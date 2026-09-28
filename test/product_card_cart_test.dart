import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/quantity_stepper.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_state.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_summary.dart';
import 'package:baytoti/features/catalog/presentation/widgets/product_card.dart';
import 'package:baytoti/features/family/presentation/widgets/family_product_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cart_harness.dart';
import 'support/fake_network.dart';

ProductSummary _product(String id) => ProductSummary(
      id: id,
      name: 'Product $id',
      family: const FamilyRef(id: '1', name: 'Amira Kitchen'),
      price: const Money(fils: 125500),
    );

void main() {
  late FakeNetwork network;
  late CartCubit cart;
  late List<String> added;

  setUp(() {
    network = FakeNetwork()
      ..replySample('GET', ApiEndPoint.cart, 'cart/cart.cloak_shape.json');
    added = [];
  });

  Future<void> pumpCard(
    WidgetTester tester,
    Widget child, {
    double width = 170,
  }) async {
    final session = SessionNotifier();
    cart = cartCubitOver(network, session);
    addTearDown(cart.close);
    session.signedIn();
    await cart.stream.firstWhere((s) => s.status == CartStatus.loaded);

    await tester.pumpWidget(BlocProvider<CartCubit>.value(
      value: cart,
      child: ScreenUtilScope(
        child: Builder(
          builder: (_) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(child: SizedBox(width: width, child: child)),
            ),
          ),
        ),
      ),
    ));
  }

  Widget card(String id) => ProductCard(
        product: _product(id),
        onTap: () {},
        onAdd: () => added.add(id),
      );

  Finder sign(String glyph) => find.descendant(
        of: find.byType(QuantityStepper),
        matching: find.text(glyph),
      );

  testWidgets('a product not in the cart keeps its add button', (tester) async {
    await pumpCard(tester, card('99'));

    expect(find.byType(QuantityStepper), findsNothing);
    await tester.tap(find.byType(AddButton));
    expect(added, ['99']);
  });

  testWidgets('a product in the cart shows its quantity instead', (tester) async {
    await pumpCard(tester, card('14'));

    expect(find.byType(AddButton), findsNothing);
    expect(sign('2'), findsOneWidget);
  });

  testWidgets('plus sends the next quantity and shows what the server kept',
      (tester) async {
    network.replySample(
      'PATCH',
      ApiEndPoint.cartItem('2'),
      'cart/cart_updated.cloak_shape.json',
    );
    await pumpCard(tester, card('11'));

    await tester.tap(sign('+'));
    await tester.pumpAndSettle();

    expect(network.last('PATCH').data, {'quantity': 2});
    expect(sign('3'), findsOneWidget);
  });

  testWidgets('minus above one lowers the quantity', (tester) async {
    network.replySample(
      'PATCH',
      ApiEndPoint.cartItem('3'),
      'cart/cart.cloak_shape.json',
    );
    await pumpCard(tester, card('14'));

    await tester.tap(sign('−'));
    await tester.pumpAndSettle();

    expect(network.last('PATCH').data, {'quantity': 1});
  });

  testWidgets('minus at one removes the line and brings the add button back',
      (tester) async {
    await pumpCard(tester, card('11'));
    network
      ..replySample(
        'DELETE',
        ApiEndPoint.cartItem('2'),
        'cart/cart_ack.cloak_shape.json',
      )
      ..replySample('GET', ApiEndPoint.cart, 'cart/cart_empty.cloak_shape.json');

    await tester.tap(sign('−'));
    await tester.pumpAndSettle();

    expect(network.calls.where((c) => c.method == 'DELETE'), hasLength(1));
    expect(find.byType(QuantityStepper), findsNothing);
    expect(find.byType(AddButton), findsOneWidget);
  });

  testWidgets('a compact row at a narrow phone fits the steppers',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpCard(
      tester,
      FamilyProductRow(
        products: [_product('11'), _product('14')],
        onOpen: (_) {},
        onAdd: (_) {},
      ),
      width: 320 - 32,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(QuantityStepper), findsNWidgets(2));
  });
}
