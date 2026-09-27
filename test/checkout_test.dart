import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/services/network_service.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/domain/entities/order_totals.dart';
import 'package:baytoti/features/checkout/data/datasources/checkout_data_source.dart';
import 'package:baytoti/features/checkout/data/models/checkout_models.dart';
import 'package:baytoti/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:baytoti/features/checkout/domain/entities/checkout.dart';
import 'package:baytoti/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:baytoti/features/checkout/domain/usecases/checkout_usecases.dart';
import 'package:baytoti/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:baytoti/features/checkout/presentation/cubit/checkout_state.dart';
import 'package:baytoti/features/checkout/presentation/pages/checkout_page.dart';
import 'package:baytoti/features/checkout/presentation/widgets/address_card.dart';
import 'package:baytoti/features/checkout/presentation/widgets/address_sheet.dart';
import 'package:baytoti/features/checkout/presentation/widgets/checkout_pay_footer.dart';
import 'package:baytoti/features/checkout/presentation/widgets/checkout_section.dart';
import 'package:baytoti/features/checkout/presentation/widgets/checkout_step_strip.dart';
import 'package:baytoti/features/checkout/presentation/widgets/fulfilment_selector.dart';
import 'package:baytoti/features/checkout/presentation/widgets/payment_method_list.dart';
import 'package:baytoti/features/orders/domain/entities/order.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InstantBackend extends FixtureBackend {
  @override
  Future<void> wait() async {}
}

class _RecordingNetwork implements NetworkService {
  final int statusCode;
  final Object? body;
  String? url;
  Object? data;
  Map<String, dynamic>? headers;

  _RecordingNetwork({required this.statusCode, required this.body});

  @override
  Future<Map<String, dynamic>> getDefaultHeaders([String? language]) async =>
      {'Authorization': 'Bearer token', 'Accept-Language': 'en-KW'};

  @override
  Future<Response> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async {
    this.url = url;
    this.data = data;
    this.headers = headers;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: url),
      statusCode: statusCode,
      data: body,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCheckoutRepository implements CheckoutRepository {
  Either<Failure, CheckoutOptions> options;
  Either<Failure, PlacedOrder> placed;
  final List<PlaceOrderParams> sent = [];

  _FakeCheckoutRepository({required this.options, required this.placed});

  @override
  Future<Either<Failure, CheckoutOptions>> getOptions() async => options;

  @override
  Future<Either<Failure, PlacedOrder>> placeOrder(
    PlaceOrderParams params,
  ) async {
    sent.add(params);
    return placed;
  }
}

const PlaceOrderParams _params = PlaceOrderParams(
  cartId: 'crt_55',
  addressId: 'adr_2',
  fulfilmentMethod: 'pickup',
  paymentMethod: 'knet',
  idempotencyKey: 'key-1',
);

const PlacedOrder _placed = PlacedOrder(
  orderId: 'ord_9',
  reference: 'BT-9',
  totalDisplay: '1.000 KWD',
  paymentState: PaymentState.succeeded,
);

CheckoutOptions _fixtureOptions() => CheckoutOptionsModel.fromJson(
      _InstantBackend().checkoutOptions('en'),
    );

CheckoutCubit _cubitOver(CheckoutRepository repository) => CheckoutCubit(
      GetCheckoutOptionsUseCase(repository),
      PlaceOrderUseCase(repository),
      idempotencyKey: 'key-1',
    );

Money _kwd(int fils) => Money(fils: fils, display: Money.format(fils, 'en'));

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
    test('checkout options read addresses, methods and payments', () {
      final options = _fixtureOptions();

      expect(options.addresses.single.id, 'adr_2');
      expect(options.defaultAddress?.label, 'Home — Hawalli');
      expect(options.fulfilmentMethods.map((m) => m.id), ['delivery', 'pickup']);
      expect(options.fulfilmentMethods.first.feeFils, 1500);
      expect(options.fulfilmentMethods.last.feeFils, 0);
      expect(options.firstAvailableMethod?.id, 'delivery');
      expect(options.paymentMethods.map((m) => m.id), ['knet', 'card', 'apple']);
      expect(options.paymentMethods.first.meta, 'Kuwaiti debit');
      expect(options.firstAvailablePayment?.id, 'knet');
    });

    test('an unavailable method is never chosen', () {
      final options = CheckoutOptionsModel.fromJson(const {
        'addresses': [],
        'fulfilment_methods': [
          {'id': 'delivery', 'label': 'D', 'fee_fils': 1500, 'available': false},
          {'id': 'pickup', 'label': 'P', 'fee_fils': 0, 'available': true},
        ],
        'payment_methods': [
          {'id': 'knet', 'label': 'K', 'available': false},
          {'id': 'card', 'label': 'C', 'available': true},
        ],
      });

      expect(options.defaultAddress, isNull);
      expect(options.firstAvailableMethod?.id, 'pickup');
      expect(options.method('delivery'), isNull);
      expect(options.firstAvailablePayment?.id, 'card');
    });

    test('a placed order reads the order and the payment state', () {
      final placed = PlacedOrderModel.fromJson(
        _InstantBackend().placeOrder(fulfilment: 'pickup', lang: 'en'),
      );

      expect(placed.orderId, 'ord_2042');
      expect(placed.reference, 'BT-2042');
      expect(placed.status, OrderStatus.placed);
      expect(placed.paymentState, PaymentState.succeeded);
      expect(placed.paymentRedirect, isNull);
    });

    test('a payment that needs a redirect carries its url', () {
      final placed = PlacedOrderModel.fromJson(const {
        'order': {
          'id': 'ord_5',
          'reference': 'BT-5',
          'status': 'placed',
          'total_display': '9.050 KWD',
        },
        'payment': {
          'state': 'requires_redirect',
          'redirect_url': 'https://pay.example/k/1',
          'return_url': 'baytouti://orders/ord_5',
        },
      });

      expect(placed.paymentState, PaymentState.requiresRedirect);
      expect(placed.paymentRedirect, 'https://pay.example/k/1');
      expect(placed.returnUrl, 'baytouti://orders/ord_5');
    });

    test('the order body carries every field the contract names', () {
      expect(_params.toJson(), {
        'cart_id': 'crt_55',
        'address_id': 'adr_2',
        'fulfilment_method': 'pickup',
        'payment_method': 'knet',
        'note': null,
        'idempotency_key': 'key-1',
      });
    });
  });

  group('the chosen method adjusts shipping', () {
    final cartTotals = OrderTotals(
      subtotal: _kwd(8050),
      discount: _kwd(500),
      shipping: _kwd(1500),
      total: _kwd(9050),
    );

    test('the same fee leaves the server totals alone', () {
      expect(cartTotals.withShipping(1500, 'en'), same(cartTotals));
    });

    test('a different fee replaces shipping and moves the total', () {
      final pickup = cartTotals.withShipping(0, 'en');

      expect(pickup.shipping.fils, 0);
      expect(pickup.total.fils, 7550);
      expect(pickup.total.display, '7.550 KWD');
      expect(pickup.subtotal, cartTotals.subtotal);
      expect(pickup.discount, cartTotals.discount);
    });
  });

  group('the remote data source', () {
    test('places an order with the idempotency key in body and header',
        () async {
      final network = _RecordingNetwork(
        statusCode: 201,
        body: const {
          'order': {
            'id': 'ord_9',
            'reference': 'BT-9',
            'status': 'placed',
            'total_display': '1.000 KWD',
          },
          'payment': {'state': 'succeeded'},
        },
      );

      final result = await CheckoutRemoteDataSource(network).placeOrder(_params);

      expect(network.url, ApiEndPoint.orders);
      expect(network.data, _params.toJson());
      expect(network.headers?[idempotencyHeader], 'key-1');
      expect(network.headers?['Authorization'], 'Bearer token');
      expect(result.fold((_) => null, (o) => o.orderId), 'ord_9');
    });

    test('a refusal keeps the server message', () async {
      final network = _RecordingNetwork(
        statusCode: 409,
        body: const {
          'success': false,
          'message': 'The cart is empty',
          'data': null,
          'errors': null,
        },
      );

      final result = await CheckoutRemoteDataSource(network).placeOrder(_params);
      final failure = result.fold((f) => f, (_) => null);

      expect(failure, isA<ServerFailure>());
      expect(failure?.message, 'The cart is empty');
    });
  });

  group('the fixture repository', () {
    test('placing an order empties the cart, so a second one is refused',
        () async {
      final backend = _InstantBackend();
      final repository = CheckoutRepositoryImpl(
        CheckoutMockDataSource(backend, () async => 'en'),
      );

      final options = await repository.getOptions();
      final first = await repository.placeOrder(_params);
      final second = await repository.placeOrder(_params);

      expect(options.isRight(), isTrue);
      expect(first.fold((_) => null, (o) => o.orderId), 'ord_2042');
      expect(backend.cart('en')['items'], isEmpty);
      expect(second.fold((f) => f.code, (_) => null), 'cart_empty');
    });
  });

  group('CheckoutCubit', () {
    test('picks the default address, first method and first payment',
        () async {
      final cubit = _cubitOver(_FakeCheckoutRepository(
        options: Right(_fixtureOptions()),
        placed: const Right(_placed),
      ));

      await cubit.load();

      expect(cubit.state.status, CheckoutStatus.loaded);
      expect(cubit.state.address?.id, 'adr_2');
      expect(cubit.state.fulfilment?.id, 'delivery');
      expect(cubit.state.payment?.id, 'knet');
      expect(cubit.state.canPlace, isTrue);
    });

    test('changes method and payment, ignoring unknown ids', () async {
      final cubit = _cubitOver(_FakeCheckoutRepository(
        options: Right(_fixtureOptions()),
        placed: const Right(_placed),
      ));
      await cubit.load();

      cubit.selectFulfilment('pickup');
      cubit.selectPayment('apple');
      cubit.selectPayment('cash');

      expect(cubit.state.fulfilment?.id, 'pickup');
      expect(cubit.state.payment?.id, 'apple');
    });

    test('a failed first read is an error screen', () async {
      final cubit = _cubitOver(_FakeCheckoutRepository(
        options: const Left(NetworkFailure(message: 'offline')),
        placed: const Right(_placed),
      ));

      await cubit.load();

      expect(cubit.state.status, CheckoutStatus.error);
      expect(cubit.state.errorMessage, 'offline');
    });

    test('places the order with the screen key and the choices', () async {
      final repository = _FakeCheckoutRepository(
        options: Right(_fixtureOptions()),
        placed: const Right(_placed),
      );
      final cubit = _cubitOver(repository);
      await cubit.load();
      cubit.selectFulfilment('pickup');

      await cubit.placeOrder('crt_55');
      await cubit.placeOrder('crt_55');

      expect(repository.sent, [_params]);
      expect(cubit.state.placedOrder, _placed);
      expect(cubit.state.isBusy, isTrue);
      expect(cubit.state.canPlace, isFalse);
    });

    test('a refused order reports why and can be tried again', () async {
      final repository = _FakeCheckoutRepository(
        options: Right(_fixtureOptions()),
        placed: const Left(ServerFailure(message: 'order_place_failed')),
      );
      final cubit = _cubitOver(repository);
      await cubit.load();

      await cubit.placeOrder('crt_55');

      expect(cubit.state.errorMessage, 'order_place_failed');
      expect(cubit.state.isPlacing, isFalse);
      expect(cubit.state.placedOrder, isNull);
      expect(cubit.state.canPlace, isTrue);

      repository.placed = const Right(_placed);
      await cubit.placeOrder('crt_55');

      expect(repository.sent.map((p) => p.idempotencyKey), ['key-1', 'key-1']);
      expect(cubit.state.placedOrder, _placed);
    });

    test('each checkout screen gets its own key', () {
      expect(
        CheckoutCubit.newIdempotencyKey(),
        isNot(CheckoutCubit.newIdempotencyKey()),
      );
    });
  });

  group('widgets', () {
    testWidgets('the checkout sections lay out and report choices',
        (tester) async {
      final options = _fixtureOptions();
      final chosen = <String>[];
      var paid = 0;

      await tester.pumpWidget(_app(ListView(
        children: [
          const CheckoutStepStrip(),
          CheckoutSection(
            label: 'checkout_address',
            actionLabel: 'checkout_change',
            onAction: () {},
            child: AddressCard(
              label: options.addresses.first.label,
              line: options.addresses.first.line,
            ),
          ),
          CheckoutSection(
            label: 'checkout_fulfilment',
            child: FulfilmentSelector(
              methods: options.fulfilmentMethods,
              selectedId: 'delivery',
              onSelect: chosen.add,
            ),
          ),
          CheckoutSection(
            label: 'checkout_payment',
            child: PaymentMethodList(
              methods: options.paymentMethods,
              selectedId: 'knet',
              onSelect: chosen.add,
            ),
          ),
          CheckoutPayFooter(
            totalDisplay: '9.050 KWD',
            isLoading: false,
            onPay: () => paid++,
          ),
        ],
      )));

      expect(find.text('01'), findsOneWidget);
      expect(find.text('Home — Hawalli'), findsOneWidget);

      await tester.tap(find.text('Pickup'));
      await tester.tap(find.text('Apple Pay'));
      await tester.tap(find.text('checkout_confirm_pay'));

      expect(chosen, ['pickup', 'apple']);
      expect(paid, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the address sheet returns the picked address',
        (tester) async {
      String? picked;

      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await showAddressSheet(
              context,
              addresses: const [
                CheckoutAddress(id: 'adr_1', label: 'Work', line: 'Sharq'),
                CheckoutAddress(id: 'adr_2', label: 'Home', line: 'Hawalli'),
              ],
              selectedId: 'adr_2',
            );
          },
          child: const Text('open'),
        ),
      )));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      expect(picked, 'adr_1');
    });
  });

  group('the checkout page', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    tearDown(() => GetIt.instance.reset());

    testWidgets('pickup drops the shipping, and placing opens the order',
        (tester) async {
      final backend = _InstantBackend();
      final checkout = CheckoutRepositoryImpl(
        CheckoutMockDataSource(backend, () async => 'en'),
      );
      final cart = CartRepositoryImpl(
        CartMockDataSource(backend, () async => 'en'),
      );
      GetIt.instance.registerFactory(() => CheckoutCubit(
            GetCheckoutOptionsUseCase(checkout),
            PlaceOrderUseCase(checkout),
          ));
      final cartCubit = CartCubit(
        GetCartUseCase(cart),
        AddToCartUseCase(cart),
        UpdateCartItemUseCase(cart),
        RemoveCartItemUseCase(cart),
        ApplyCouponUseCase(cart),
        SessionNotifier()..signedIn(),
      );
      addTearDown(cartCubit.close);
      final router = GoRouter(
        initialLocation: '/cart/checkout',
        routes: [
          GoRoute(
            path: '/cart',
            builder: (_, _) => const Text('cart root'),
            routes: [
              GoRoute(
                path: 'checkout',
                builder: (_, _) => const CheckoutPage(),
              ),
              GoRoute(
                path: 'orders/:id',
                builder: (_, state) =>
                    Text('order ${state.pathParameters['id']}'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.runAsync(() async {
        await tester.pumpWidget(EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          saveLocale: false,
          child: Builder(
            builder: (context) => BlocProvider<CartCubit>.value(
              value: cartCubit,
              child: ScreenUtilScope(
                child: Builder(
                  builder: (_) => MaterialApp.router(
                    theme: AppTheme.light,
                    locale: context.locale,
                    supportedLocales: context.supportedLocales,
                    localizationsDelegates: context.localizationDelegates,
                    routerConfig: router,
                  ),
                ),
              ),
            ),
          ),
        ));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      expect(find.text('Home — Hawalli'), findsOneWidget);
      expect(find.text('9.050 د.ك'), findsWidgets);

      await tester.tap(find.text('Pickup'));
      await tester.pumpAndSettle();
      expect(find.text('7.550 KWD'), findsWidgets);

      final pay = find.text('Confirm and pay');
      await tester.scrollUntilVisible(pay, 200);
      await tester.tap(pay);
      await tester.pumpAndSettle();

      expect(find.text('order ord_2042'), findsOneWidget);
      expect(cartCubit.state.cart?.isEmpty, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
