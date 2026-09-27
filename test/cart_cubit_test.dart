import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

void main() {
  late FakeNetwork network;
  late SessionNotifier session;
  late CartCubit cubit;

  setUp(() {
    network = FakeNetwork()
      ..replySample('GET', ApiEndPoint.cart, 'cart/cart.cloak_shape.json');
    session = SessionNotifier();
    final repository = CartRepositoryImpl(CartRemoteDataSource(network));
    cubit = CartCubit(
      GetCartUseCase(repository),
      AddToCartUseCase(repository),
      UpdateCartItemUseCase(repository),
      RemoveCartItemUseCase(repository),
      session,
    );
  });

  tearDown(() => cubit.close());

  Future<void> signIn() async {
    session.signedIn();
    await cubit.stream.firstWhere((s) => s.status == CartStatus.loaded);
  }

  test('a guest has no cart and nothing is read', () async {
    session.signedOut();
    await cubit.load();

    expect(cubit.state.status, CartStatus.initial);
    expect(cubit.state.itemCount, 0);
    expect(network.calls, isEmpty);
  });

  test('a session start reads the cart and counts units', () async {
    await signIn();

    expect(network.last('GET').url, ApiEndPoint.cart);
    expect(cubit.state.itemCount, 3);
  });

  test('a failed first read is an error, a failed reread keeps the cart',
      () async {
    network.replySample(
      'GET',
      ApiEndPoint.cart,
      'betouti/products_guest_500.json',
      status: 500,
    );
    session.signedIn();
    await cubit.stream.firstWhere((s) => s.status == CartStatus.error);
    expect(cubit.state.errorMessage, 'server_error');

    network.replySample('GET', ApiEndPoint.cart, 'cart/cart.cloak_shape.json');
    await cubit.load();
    network.replySample(
      'GET',
      ApiEndPoint.cart,
      'betouti/products_guest_500.json',
      status: 500,
    );
    await cubit.load();

    expect(cubit.state.status, CartStatus.loaded);
    expect(cubit.state.itemCount, 3);
    expect(cubit.state.errorMessage, 'server_error');
  });

  test('adding lands the cart the server answered with', () async {
    await signIn();
    network.replySample(
      'POST',
      ApiEndPoint.cartItems,
      'cart/cart_added.cloak_shape.json',
      status: 201,
    );

    final failure = await cubit.add('20', 2);

    expect(failure, isNull);
    expect(network.last('POST').data, {'product_id': 20, 'quantity': 2});
    expect(cubit.state.itemCount, 5);
    expect(cubit.state.isAdding, isFalse);
  });

  test('a refused add is returned to the caller and keeps the cart',
      () async {
    await signIn();
    network.replySample(
      'POST',
      ApiEndPoint.cartItems,
      'cart/cart_quantity_422.cloak_shape.json',
      status: 422,
    );

    final failure = await cubit.add('20', 9);

    expect(failure, isA<ValidationFailure>());
    expect(cubit.state.itemCount, 3);
    expect(cubit.state.isAdding, isFalse);
  });

  test('a quantity change sends the new count and clears the busy line',
      () async {
    await signIn();
    network.replySample(
      'PATCH',
      ApiEndPoint.cartItem('2'),
      'cart/cart_updated.cloak_shape.json',
    );

    await cubit.setQuantity(cubit.state.cart!.items.first, 3);

    expect(network.last('PATCH').data, {'quantity': 3});
    expect(cubit.state.cart!.items.first.quantity, 3);
    expect(cubit.state.cart!.totals.subtotal.fils, 16550);
    expect(cubit.state.busyItemIds, isEmpty);
  });

  test('a quantity below one is never sent', () async {
    await signIn();
    final before = network.calls.length;

    await cubit.setQuantity(cubit.state.cart!.items.first, 0);

    expect(network.calls, hasLength(before));
  });

  test('a removal answered with no cart rereads it', () async {
    await signIn();
    network
      ..replySample(
        'DELETE',
        ApiEndPoint.cartItem('3'),
        'cart/cart_ack.cloak_shape.json',
      )
      ..replySample(
        'GET',
        ApiEndPoint.cart,
        'cart/cart_empty.cloak_shape.json',
      );

    await cubit.remove(cubit.state.cart!.items.last);

    expect(network.calls.last.method, 'GET');
    expect(cubit.state.cart!.isEmpty, isTrue);
  });

  test('a failed removal keeps the cart and reports why', () async {
    await signIn();
    final before = cubit.state.cart;
    network.replySample(
      'DELETE',
      ApiEndPoint.cartItem('3'),
      'betouti/unauthenticated_401.json',
      status: 401,
    );

    await cubit.remove(before!.items.last);

    expect(cubit.state.cart, before);
    expect(cubit.state.errorMessage, 'Unauthenticated.');
    expect(cubit.state.busyItemIds, isEmpty);
  });

  test('a session end empties the cart', () async {
    await signIn();

    session.signedOut();

    expect(cubit.state, const CartState());
    expect(cubit.state.itemCount, 0);
  });
}
