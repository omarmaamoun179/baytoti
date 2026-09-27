import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/models/cart_model.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_state.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the fixture cart parses as the contract describes it', () {
    final cart = CartModel.fromJson(FixtureBackend().cart('ar'));

    expect(cart.items.map((i) => i.productId), ['prd_1', 'prd_3']);
    expect(cart.items.first.lineTotal.display, '4.250 د.ك');
    expect(cart.coupon?.code, FixtureBackend.validCoupon);
    expect(cart.totals.subtotal.fils, 4250 + 1900 * 2);
    expect(cart.totals.total.fils, 8050 - 500 + 1500);
    expect(cart.itemCount, 2);
  });

  group('CartCubit', () {
    late SessionNotifier session;
    late CartCubit cubit;

    setUp(() {
      session = SessionNotifier();
      final repository = CartRepositoryImpl(
        CartMockDataSource(FixtureBackend(), () async => 'en'),
      );
      cubit = CartCubit(
        GetCartUseCase(repository),
        AddToCartUseCase(repository),
        UpdateCartItemUseCase(repository),
        RemoveCartItemUseCase(repository),
        ApplyCouponUseCase(repository),
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
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, CartStatus.initial);
      expect(cubit.state.itemCount, 0);
    });

    test('a session start reads the cart', () async {
      await signIn();

      expect(cubit.state.itemCount, 2);
    });

    test('adding a new product grows the cart', () async {
      await signIn();

      final failure = await cubit.add('prd_5', 2);

      expect(failure, isNull);
      expect(cubit.state.itemCount, 3);
    });

    test('adding past the stock is refused with the contract code', () async {
      await signIn();

      final failure = await cubit.add('prd_4', 9);

      expect(failure?.code, 'stock_insufficient');
      expect(cubit.state.itemCount, 2);
    });

    test('quantity changes and removal come back recalculated', () async {
      await signIn();
      final line = cubit.state.cart!.items.first;

      await cubit.setQuantity(line, 3);
      expect(cubit.state.cart!.items.first.quantity, 3);
      expect(cubit.state.cart!.items.first.lineTotal.fils, 4250 * 3);

      await cubit.remove(cubit.state.cart!.items.first);
      expect(cubit.state.itemCount, 1);
    });

    test('an unknown coupon is refused', () async {
      await signIn();

      final failure = await cubit.applyCoupon('NOPE');

      expect(failure?.code, 'coupon_invalid');
    });

    test('a session end empties the cart', () async {
      await signIn();

      session.signedOut();

      expect(cubit.state.cart, isNull);
      expect(cubit.state.itemCount, 0);
    });
  });
}
