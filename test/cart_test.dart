import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/quantity_stepper.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/entities/cart.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/cart/presentation/pages/cart_page.dart';
import 'package:baytoti/features/cart/presentation/widgets/cart_line_tile.dart';
import 'package:baytoti/features/cart/presentation/widgets/totals_table.dart';
import 'package:baytoti/features/catalog/domain/entities/order_totals.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

class _OfflineNetwork extends FakeNetwork {
  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async =>
      throw const ConnectionException();
}

Cart _cartOf(Either<Failure, Cart> result) =>
    result.getOrElse(() => throw StateError('refused: $result'));

Failure _failureOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => throw StateError('succeeded'));

CartCubit _cubitOver(FakeNetwork network, SessionNotifier session) {
  final repository = CartRepositoryImpl(CartRemoteDataSource(network));
  return CartCubit(
    GetCartUseCase(repository),
    AddToCartUseCase(repository),
    UpdateCartItemUseCase(repository),
    RemoveCartItemUseCase(repository),
    session,
  );
}

CartItem _item({int quantity = 1, int maxQuantity = 5}) => CartItem(
      id: '2',
      productId: '11',
      name: 'Chicken machboos',
      unitPrice: const Money(fils: 1000),
      quantity: quantity,
      lineTotal: Money(fils: 1000 * quantity),
      maxQuantity: maxQuantity,
    );

Widget _app(Widget child) => ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    );

void main() {
  late FakeNetwork network;
  late CartRemoteDataSource source;

  setUp(() {
    network = FakeNetwork()
      ..replySample('GET', ApiEndPoint.cart, 'cart/cart.cloak_shape.json');
    source = CartRemoteDataSource(network);
  });

  group('the cloak cart shape', () {
    test('a line reads its ids, product, prices and photo', () async {
      final cart = _cartOf(await source.getCart());

      expect(cart.items.map((i) => i.id), ['2', '3']);
      expect(cart.items.map((i) => i.productId), ['11', '14']);
      expect(cart.items.first.name, 'مجبوس دجاج');
      expect(cart.items.first.unitPrice.fils, 4250);
      expect(cart.items.first.lineTotal.fils, 4250);
      expect(cart.items.first.image, isNull);
      expect(cart.items.first.family.name, isEmpty);
      expect(cart.items.first.maxQuantity, CartItem.defaultMaxQuantity);
      expect(cart.items.last.quantity, 2);
      expect(cart.items.last.lineTotal.fils, 3800);
      expect(
        cart.items.last.image?.url,
        'https://images.example.com/maamoul.jpg',
      );
    });

    test('the totals come from the summary, and nothing invents a fee',
        () async {
      final cart = _cartOf(await source.getCart());

      expect(cart.totals.subtotal.fils, 8050);
      expect(cart.totals.discount.fils, 0);
      expect(cart.totals.shipping.fils, 0);
      expect(cart.totals.total.fils, 8050);
      expect(cart.itemCount, 3);
    });

    test('an empty cart is read, not thrown on', () async {
      network.replySample(
        'GET',
        ApiEndPoint.cart,
        'cart/cart_empty.cloak_shape.json',
      );

      final cart = _cartOf(await source.getCart());

      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.totals.total.fils, 0);
    });
  });

  group('the remote data source', () {
    test('adding posts the numeric product id and reads the answer',
        () async {
      network.replySample(
        'POST',
        ApiEndPoint.cartItems,
        'cart/cart_added.cloak_shape.json',
        status: 201,
      );

      final cart = _cartOf(await source.addItem('20', 2));

      expect(network.last('POST').data, {'product_id': 20, 'quantity': 2});
      expect(network.calls.map((c) => c.method), ['POST']);
      expect(cart.items.last.productId, '20');
      expect(cart.totals.subtotal.fils, 13050);
    });

    test('a quantity change patches the line to an absolute value', () async {
      network.replySample(
        'PATCH',
        ApiEndPoint.cartItem('2'),
        'cart/cart_updated.cloak_shape.json',
      );

      final cart = _cartOf(await source.updateItem('2', 3));

      expect(network.last('PATCH').url, ApiEndPoint.cartItem('2'));
      expect(network.last('PATCH').data, {'quantity': 3});
      expect(cart.items.first.quantity, 3);
      expect(cart.items.first.lineTotal.fils, 12750);
    });

    test('a removal answered without the cart reads it back', () async {
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

      final cart = _cartOf(await source.removeItem('3'));

      expect(network.calls.map((c) => '${c.method} ${c.url}'), [
        'DELETE ${ApiEndPoint.cartItem('3')}',
        'GET ${ApiEndPoint.cart}',
      ]);
      expect(cart.isEmpty, isTrue);
    });

    test('a refused quantity is a field error', () async {
      network.replySample(
        'PATCH',
        ApiEndPoint.cartItem('2'),
        'cart/cart_quantity_422.cloak_shape.json',
        status: 422,
      );

      final failure = _failureOf(await source.updateItem('2', 9));

      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure)['quantity'],
        'The quantity field must not be greater than 8.',
      );
    });

    test('a line that is gone reads as a failed update', () async {
      network.reply(
        'DELETE',
        ApiEndPoint.cartItem('9'),
        status: 404,
        body: const {
          'message': 'No query results for model [App\\Models\\CartItem] 9',
        },
      );

      final failure = _failureOf(await source.removeItem('9'));

      expect(failure.statusCode, 404);
      expect(failure.message, 'cart_update_failed');
    });

    test('without a token the cart is a 401, not an empty cart', () async {
      network.replySample(
        'GET',
        ApiEndPoint.cart,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      final failure = _failureOf(await source.getCart());

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
    });

    test('a server error shows the generic message', () async {
      network.replySample(
        'POST',
        ApiEndPoint.cartItems,
        'betouti/products_guest_500.json',
        status: 500,
      );

      final failure = _failureOf(await source.addItem('20', 1));

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'server_error');
    });

    test('offline is a network failure', () async {
      final offline = CartRemoteDataSource(_OfflineNetwork());

      expect(_failureOf(await offline.getCart()), isA<NetworkFailure>());
    });
  });

  group('widgets', () {
    testWidgets('the totals table leaves out a zero discount and fee',
        (tester) async {
      await tester.pumpWidget(_app(const TotalsTable(
        totals: OrderTotals(
          subtotal: Money(fils: 8050),
          discount: Money(fils: 0),
          shipping: Money(fils: 0),
          total: Money(fils: 8050),
        ),
      )));

      expect(find.text('cart_discount'), findsNothing);
      expect(find.text('cart_shipping'), findsNothing);
      expect(find.text(const Money(fils: 8050).display), findsNWidgets(2));

      await tester.pumpWidget(_app(const TotalsTable(
        totals: OrderTotals(
          subtotal: Money(fils: 8050),
          discount: Money(fils: 500),
          shipping: Money(fils: 1500),
          total: Money(fils: 9050),
        ),
      )));

      expect(
        find.text('− ${const Money(fils: 500).display}'),
        findsOneWidget,
      );
      expect(find.text(const Money(fils: 1500).display), findsOneWidget);
    });

    testWidgets('a line cannot go below one or above its maximum',
        (tester) async {
      Future<QuantityStepper> stepperFor(CartItem item, bool busy) async {
        await tester.pumpWidget(_app(CartLineTile(
          item: item,
          busy: busy,
          onQuantity: (_) {},
          onRemove: () {},
        )));
        return tester.widget<QuantityStepper>(find.byType(QuantityStepper));
      }

      final single = await stepperFor(_item(), false);
      expect(single.onDecrement, isNull);
      expect(single.onIncrement, isNotNull);

      final full = await stepperFor(_item(quantity: 5), false);
      expect(full.onDecrement, isNotNull);
      expect(full.onIncrement, isNull);

      final busy = await stepperFor(_item(quantity: 3), true);
      expect(busy.onDecrement, isNull);
      expect(busy.onIncrement, isNull);
    });

    testWidgets('the cart page shows the server lines and sends a step',
        (tester) async {
      network.replySample(
        'PATCH',
        ApiEndPoint.cartItem('2'),
        'cart/cart_updated.cloak_shape.json',
      );
      final cubit = _cubitOver(network, SessionNotifier()..signedIn());
      addTearDown(cubit.close);

      await tester.pumpWidget(BlocProvider<CartCubit>.value(
        value: cubit,
        child: _app(const CartPage()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CartLineTile), findsNWidgets(2));
      expect(find.text('مجبوس دجاج'), findsOneWidget);

      await tester.tap(find.text('+').first);
      await tester.pumpAndSettle();

      expect(network.last('PATCH').data, {'quantity': 2});
      expect(cubit.state.cart?.items.first.quantity, 3);
      expect(find.text(const Money(fils: 16550).display), findsWidgets);
    });

    testWidgets('an empty cart says so', (tester) async {
      network.replySample(
        'GET',
        ApiEndPoint.cart,
        'cart/cart_empty.cloak_shape.json',
      );
      final cubit = _cubitOver(network, SessionNotifier()..signedIn());
      addTearDown(cubit.close);

      await tester.pumpWidget(BlocProvider<CartCubit>.value(
        value: cubit,
        child: _app(const CartPage()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('cart_empty'), findsOneWidget);
      expect(find.byType(TotalsTable), findsNothing);
    });
  });
}
