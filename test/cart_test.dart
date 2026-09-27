import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/quantity_stepper.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/models/cart_model.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/entities/cart.dart';
import 'package:baytoti/features/cart/domain/repositories/cart_repository.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_state.dart';
import 'package:baytoti/features/cart/presentation/pages/cart_page.dart';
import 'package:baytoti/features/cart/presentation/widgets/cart_line_tile.dart';
import 'package:baytoti/features/cart/presentation/widgets/totals_table.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/order_totals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _InstantBackend extends FixtureBackend {
  @override
  Future<void> wait() async {}
}

CartRepository _fixtureRepository([FixtureBackend? backend]) =>
    CartRepositoryImpl(
      CartMockDataSource(backend ?? _InstantBackend(), () async => 'en'),
    );

CartCubit _cubitOver(CartRepository repository, SessionNotifier session) =>
    CartCubit(
      GetCartUseCase(repository),
      AddToCartUseCase(repository),
      UpdateCartItemUseCase(repository),
      RemoveCartItemUseCase(repository),
      ApplyCouponUseCase(repository),
      session,
    );

Money _kwd(int fils) => Money(fils: fils, display: Money.format(fils, 'en'));

CartItem _item({int quantity = 1, int maxQuantity = 5}) => CartItem(
      id: 'ci_x',
      productId: 'prd_x',
      name: 'Date maamoul',
      family: const FamilyRef(id: 'fam_1', name: 'Umm Abdullah'),
      unitPrice: _kwd(1000),
      quantity: quantity,
      lineTotal: _kwd(1000 * quantity),
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
  group('the contract shape', () {
    test('the fixture cart reads its lines, coupon and totals', () {
      final cart = CartModel.fromJson(_InstantBackend().cart('en'));

      expect(cart.id, 'crt_55');
      expect(cart.items.map((i) => i.id), ['ci_prd_1', 'ci_prd_3']);
      expect(cart.items.first.maxQuantity, 8);
      expect(cart.items.last.quantity, 2);
      expect(cart.items.last.lineTotal.fils, 3800);
      expect(cart.coupon?.code, 'BAYT10');
      expect(cart.totals.subtotal.fils, 8050);
      expect(cart.totals.discount.fils, 500);
      expect(cart.totals.shipping.fils, 1500);
      expect(cart.totals.total.fils, 9050);
      expect(cart.totals.total.display, '9.050 د.ك');
    });
  });

  group('the fixture repository', () {
    test('more than the stock is refused with the field', () async {
      final result = await _fixtureRepository().updateItem('ci_prd_1', 9);
      final failure = result.fold((f) => f, (_) => null);

      expect(failure, isA<ValidationFailure>());
      expect(failure?.code, 'stock_insufficient');
      expect((failure as ValidationFailure?)?['quantity'], '8 available');
    });

    test('an unknown code is refused', () async {
      final result = await _fixtureRepository().applyCoupon('NOPE');

      expect(result.fold((f) => f.code, (_) => null), 'coupon_invalid');
    });

    test('a removed line leaves the cart recalculated', () async {
      final result = await _fixtureRepository().removeItem('ci_prd_3');
      final cart = result.getOrElse(() => throw StateError('failed'));

      expect(cart.items.single.id, 'ci_prd_1');
      expect(cart.totals.subtotal.fils, 4250);
    });
  });

  group('CartCubit', () {
    test('a session start loads the cart, a sign-out forgets it', () async {
      final session = SessionNotifier();
      final cubit = _cubitOver(_fixtureRepository(), session);

      session.signedIn();
      await cubit.stream.firstWhere((s) => s.status == CartStatus.loaded);
      expect(cubit.state.itemCount, 2);

      session.signedOut();
      expect(cubit.state, const CartState());
      await cubit.close();
    });

    test('a quantity change lands the server cart', () async {
      final session = SessionNotifier()..signedIn();
      final cubit = _cubitOver(_fixtureRepository(), session);
      await cubit.load();

      await cubit.setQuantity(cubit.state.cart!.items.first, 3);

      expect(cubit.state.cart?.items.first.quantity, 3);
      expect(cubit.state.cart?.totals.subtotal.fils, 4250 * 3 + 3800);
      expect(cubit.state.busyItemIds, isEmpty);
      await cubit.close();
    });

    test('a failed removal keeps the cart and reports why', () async {
      final session = SessionNotifier()..signedIn();
      final cubit = _cubitOver(_fixtureRepository(), session);
      await cubit.load();
      final before = cubit.state.cart;

      await cubit.remove(_item());

      expect(cubit.state.cart, before);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.busyItemIds, isEmpty);
      await cubit.close();
    });

    test('a refused coupon is returned to the caller', () async {
      final session = SessionNotifier()..signedIn();
      final cubit = _cubitOver(_fixtureRepository(), session);
      await cubit.load();

      final refused = await cubit.applyCoupon('NOPE');
      final applied = await cubit.applyCoupon('bayt10');

      expect(refused?.code, 'coupon_invalid');
      expect(applied, isNull);
      expect(cubit.state.cart?.coupon?.code, 'BAYT10');
      expect(cubit.state.isApplyingCoupon, isFalse);
      await cubit.close();
    });
  });

  group('widgets', () {
    testWidgets('the totals table marks the discount', (tester) async {
      await tester.pumpWidget(_app(TotalsTable(
        totals: OrderTotals(
          subtotal: _kwd(8050),
          discount: _kwd(500),
          shipping: _kwd(1500),
          total: _kwd(9050),
        ),
      )));

      expect(find.text('8.050 KWD'), findsOneWidget);
      expect(find.text('− 0.500 KWD'), findsOneWidget);
      expect(find.text('1.500 KWD'), findsOneWidget);
      expect(find.text('9.050 KWD'), findsOneWidget);
    });

    testWidgets('a line cannot go below one or above its stock',
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

    testWidgets('the cart page shows lines and applies a code',
        (tester) async {
      final session = SessionNotifier()..signedIn();
      final cubit = _cubitOver(_fixtureRepository(), session);
      addTearDown(cubit.close);

      await tester.pumpWidget(BlocProvider<CartCubit>.value(
        value: cubit,
        child: _app(const CartPage()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CartLineTile), findsNWidgets(2));
      expect(find.text('BAYT10'), findsOneWidget);

      await tester.tap(find.text('+').first);
      await tester.pumpAndSettle();
      expect(cubit.state.cart?.items.first.quantity, 2);

      await tester.enterText(find.byType(TextField), 'NOPE');
      await tester.tap(find.text('cart_apply'));
      await tester.pumpAndSettle();
      expect(find.text('That discount code is not valid'), findsOneWidget);
    });

    testWidgets('an empty cart says so', (tester) async {
      final backend = _InstantBackend();
      backend.removeCartItem('ci_prd_1', 'en');
      backend.removeCartItem('ci_prd_3', 'en');
      final session = SessionNotifier()..signedIn();
      final cubit = _cubitOver(_fixtureRepository(backend), session);
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
