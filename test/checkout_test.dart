import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/network/api_response.dart';
import 'package:baytoti/core/routing/routes.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/app_button.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_state.dart';
import 'package:baytoti/features/catalog/domain/entities/image_ref.dart';
import 'package:baytoti/features/checkout/data/datasources/checkout_data_source.dart';
import 'package:baytoti/features/checkout/data/models/checkout_models.dart';
import 'package:baytoti/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:baytoti/features/checkout/domain/entities/checkout.dart';
import 'package:baytoti/features/checkout/domain/usecases/checkout_usecases.dart';
import 'package:baytoti/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:baytoti/features/checkout/presentation/cubit/checkout_state.dart';
import 'package:baytoti/features/checkout/presentation/pages/checkout_page.dart';
import 'package:baytoti/features/checkout/presentation/widgets/address_sheet.dart';
import 'package:baytoti/features/orders/data/models/order_models.dart';
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

Map<String, dynamic> _order(int id, String store) => {
      'id': id,
      'order_number': 'ORD-2026-$id',
      'status': 'pending',
      'financials': {
        'subtotal': '4.250',
        'discount': '0.000',
        'shipping_fee': '1.000',
        'total': '5.250',
      },
      'store': {'id': id, 'name': store, 'slug': 'store-$id'},
    };

Map<String, dynamic> _address(int id, {bool isDefault = false}) => {
      'id': id,
      'label': 'Address $id',
      'city': 'Hawalli',
      'area': 'Salmiya',
      'street': '$id',
      'is_default': isDefault,
    };

ApiResponse _answer(Object? data) => checkedResponse(Response<dynamic>(
      requestOptions: RequestOptions(path: ApiEndPoint.checkout),
      statusCode: 200,
      data: {'success': true, 'message': 'Order placed.', 'data': data},
    ));

T _valueOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('refused: $result'));

Failure _failureOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => throw StateError('succeeded'));

CheckoutCubit _cubitOver(FakeNetwork network) {
  final repository = CheckoutRepositoryImpl(CheckoutRemoteDataSource(network));
  return CheckoutCubit(
    GetCheckoutAddressesUseCase(repository),
    PlaceOrderUseCase(repository),
  );
}

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
  late CheckoutRemoteDataSource source;

  setUp(() {
    network = FakeNetwork()
      ..replySample(
        'GET',
        ApiEndPoint.addresses,
        'checkout/addresses.cloak_shape.json',
      )
      ..replySample(
        'POST',
        ApiEndPoint.checkout,
        'checkout/checkout_orders.cloak_shape.json',
        status: 201,
      );
    source = CheckoutRemoteDataSource(network);
  });

  group('the cloak address shape', () {
    test('an address reads its id, label and Kuwaiti line', () async {
      final addresses = _valueOf(await source.getAddresses());

      expect(addresses.map((a) => a.id), ['1', '2']);
      expect(addresses.map((a) => a.label), ['Work', 'Home']);
      expect(addresses.first.line, 'Sharq, 2, Jaber Al-Mubarak, 14, 6');
      expect(addresses.last.line, 'Salmiya, 4, 12, 8, 3');
      expect(addresses.preferred?.id, '2');
      expect(addresses.byId('1')?.isDefault, isFalse);
    });

    test('a blank label or line falls back to the city', () {
      final address = CheckoutAddressModel.fromJson(const {
        'id': 4,
        'label': ' ',
        'city': 'Hawalli',
      });

      expect(address.label, 'Hawalli');
      expect(address.line, 'Hawalli');
    });

    test('a row without an id is dropped: it could not be sent', () {
      final addresses = CheckoutAddressModel.listFrom([
        {'label': 'Nowhere'},
        _address(3),
      ]);

      expect(addresses.map((a) => a.id), ['3']);
      expect(addresses.preferred?.id, '3');
    });
  });

  group('the checkout request', () {
    test('carries the address by its number and pays cash on delivery', () {
      expect(const PlaceOrderParams(addressId: '2').toJson(), {
        'address_id': 2,
        'payment_method': 'cash_on_delivery',
      });
    });

    test('a note goes trimmed, a blank one not at all', () {
      expect(
        const PlaceOrderParams(addressId: '2', notes: ' no onion ').toJson(),
        {
          'address_id': 2,
          'payment_method': 'cash_on_delivery',
          'notes': 'no onion',
        },
      );
      expect(
        const PlaceOrderParams(addressId: '2', notes: '  ').toJson(),
        {'address_id': 2, 'payment_method': 'cash_on_delivery'},
      );
    });
  });

  group('the checkout answer', () {
    test('one order per store, as a list at data', () async {
      final orders = _valueOf(
        await source.placeOrder(const PlaceOrderParams(addressId: '2')),
      );

      expect(orders.map((o) => o.id), ['41', '42']);
      expect(orders.map((o) => o.family?.name), [
        'مطبخ أم عبدالله',
        'حلويات نورة',
      ]);
      expect(orders.first.status, OrderStatus.pending);
      expect(orders.first.total.fils, 5250);
    });

    test('a list at data.orders, and a single order', () {
      expect(
        OrderSummaryModel.listFromCheckout(_answer({
          'orders': [_order(7, 'A')],
        })).map((o) => o.id),
        ['7'],
      );
      expect(
        OrderSummaryModel.listFromCheckout(_answer(_order(9, 'B'))).single.id,
        '9',
      );
      expect(
        OrderSummaryModel.listFromCheckout(_answer({'order': _order(5, 'C')}))
            .single
            .reference,
        'ORD-2026-5',
      );
    });

    test('a success that names no order is still a success', () {
      expect(OrderSummaryModel.listFromCheckout(_answer(null)), isEmpty);
      expect(
        OrderSummaryModel.listFromCheckout(_answer({'message': 'ok'})),
        isEmpty,
      );
    });
  });

  group('the remote data source', () {
    test('addresses are read from the address book', () async {
      await source.getAddresses();

      expect(network.last('GET').url, ApiEndPoint.addresses);
    });

    test('checkout posts the address to orders/checkout', () async {
      await source.placeOrder(const PlaceOrderParams(addressId: '2'));

      expect(network.last('POST').url, ApiEndPoint.checkout);
      expect(network.last('POST').data, {
        'address_id': 2,
        'payment_method': 'cash_on_delivery',
      });
      expect(network.last('POST').headers, isNull);
    });

    test('a refused address is a field error', () async {
      network.replySample(
        'POST',
        ApiEndPoint.checkout,
        'checkout/checkout_address_422.cloak_shape.json',
        status: 422,
      );

      final failure = _failureOf(
        await source.placeOrder(const PlaceOrderParams(addressId: '99')),
      );

      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure)['address_id'],
        'The selected address id is invalid.',
      );
    });

    test('without a token the addresses are a 401', () async {
      network.replySample(
        'GET',
        ApiEndPoint.addresses,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      final failure = _failureOf(await source.getAddresses());

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
    });

    test('a server error shows the generic message', () async {
      network.replySample(
        'POST',
        ApiEndPoint.checkout,
        'betouti/products_guest_500.json',
        status: 500,
      );

      final failure = _failureOf(
        await source.placeOrder(const PlaceOrderParams(addressId: '2')),
      );

      expect(failure.message, 'server_error');
    });

    test('offline is a network failure', () async {
      final offline = CheckoutRemoteDataSource(_OfflineNetwork());

      expect(_failureOf(await offline.getAddresses()), isA<NetworkFailure>());
    });
  });

  group('CheckoutCubit', () {
    late CheckoutCubit cubit;

    setUp(() => cubit = _cubitOver(network));

    tearDown(() => cubit.close());

    test('picks the default address', () async {
      await cubit.load();

      expect(cubit.state.status, CheckoutStatus.loaded);
      expect(cubit.state.address?.label, 'Home');
      expect(cubit.state.canPlace, isTrue);
    });

    test('keeps a chosen address while it exists and ignores unknown ids',
        () async {
      await cubit.load();
      cubit.selectAddress('1');
      cubit.selectAddress('404');
      expect(cubit.state.addressId, '1');

      await cubit.load();
      expect(cubit.state.addressId, '1');

      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: {
          'success': true,
          'data': [_address(3), _address(4, isDefault: true)],
        },
      );
      await cubit.load();
      expect(cubit.state.addressId, '4');
    });

    test('no saved address means nothing can be placed', () async {
      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: const {'success': true, 'data': []},
      );

      await cubit.load();
      await cubit.placeOrder();

      expect(cubit.state.status, CheckoutStatus.loaded);
      expect(cubit.state.address, isNull);
      expect(cubit.state.canPlace, isFalse);
      expect(network.calls.where((c) => c.method == 'POST'), isEmpty);
    });

    test('an address added from checkout is the one chosen', () async {
      await cubit.load();
      expect(cubit.state.addressId, '2');

      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: {
          'success': true,
          'data': [_address(1), _address(2, isDefault: true), _address(5)],
        },
      );
      await cubit.addressAdded();

      expect(cubit.state.addressId, '5');
    });

    test('a first address makes the order possible', () async {
      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: const {'success': true, 'data': []},
      );
      await cubit.load();
      expect(cubit.state.canPlace, isFalse);

      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: {
          'success': true,
          'data': [_address(7, isDefault: true)],
        },
      );
      await cubit.addressAdded();

      expect(cubit.state.address?.id, '7');
      expect(cubit.state.canPlace, isTrue);
    });

    test('a failed first read is an error screen', () async {
      network.replySample(
        'GET',
        ApiEndPoint.addresses,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load();

      expect(cubit.state.status, CheckoutStatus.error);
      expect(cubit.state.errorMessage, 'server_error');
    });

    test('places the order for the chosen address, once', () async {
      await cubit.load();

      await cubit.placeOrder();
      await cubit.placeOrder();

      final posts = network.calls.where((c) => c.method == 'POST').toList();
      expect(posts, hasLength(1));
      expect(posts.single.data, {
        'address_id': 2,
        'payment_method': 'cash_on_delivery',
      });
      expect(cubit.state.placedOrders?.map((o) => o.id), ['41', '42']);
      expect(cubit.state.isBusy, isTrue);
      expect(cubit.state.canPlace, isFalse);
    });

    test('a refused order reports why and can be tried again', () async {
      network.replySample(
        'POST',
        ApiEndPoint.checkout,
        'checkout/checkout_address_422.cloak_shape.json',
        status: 422,
      );
      await cubit.load();

      await cubit.placeOrder();

      expect(cubit.state.errorMessage, 'The selected address id is invalid.');
      expect(cubit.state.isPlacing, isFalse);
      expect(cubit.state.placedOrders, isNull);
      expect(cubit.state.canPlace, isTrue);

      network.replySample(
        'POST',
        ApiEndPoint.checkout,
        'checkout/checkout_orders.cloak_shape.json',
        status: 201,
      );
      await cubit.placeOrder();

      expect(cubit.state.placedOrders, hasLength(2));
    });
  });

  group('widgets', () {
    testWidgets('the address sheet returns the picked address',
        (tester) async {
      String? picked;

      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await showAddressSheet(
              context,
              addresses: const [
                CheckoutAddress(id: '1', label: 'Work', line: 'Sharq'),
                CheckoutAddress(id: '2', label: 'Home', line: 'Salmiya'),
              ],
              selectedId: '2',
            );
          },
          child: const Text('open'),
        ),
      )));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('address_add'), findsNothing);
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      expect(picked, '1');
    });

    testWidgets('the address sheet hands over to adding one', (tester) async {
      var added = 0;
      String? picked = 'none yet';

      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await showAddressSheet(
              context,
              addresses: const [
                CheckoutAddress(id: '1', label: 'Work', line: 'Sharq'),
              ],
              onAdd: () => added++,
            );
          },
          child: const Text('open'),
        ),
      )));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('address_add'));
      await tester.pumpAndSettle();

      expect(added, 1);
      expect(picked, isNull);
      expect(find.text('Work'), findsNothing);
    });
  });

  group('the checkout page', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    tearDown(() => GetIt.instance.reset());

    late List<Object?> orderExtras;

    Future<CartCubit> pumpCheckout(WidgetTester tester) async {
      orderExtras = [];
      network.replySample(
        'GET',
        ApiEndPoint.cart,
        'cart/cart.cloak_shape.json',
      );
      GetIt.instance.registerFactory(() => _cubitOver(network));
      final cart = CartRepositoryImpl(CartRemoteDataSource(network));
      final cartCubit = CartCubit(
        GetCartUseCase(cart),
        AddToCartUseCase(cart),
        UpdateCartItemUseCase(cart),
        RemoveCartItemUseCase(cart),
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
                builder: (_, state) {
                  orderExtras.add(state.extra);
                  return Text('order ${state.pathParameters['id']}');
                },
              ),
              GoRoute(
                path: '${AppRoutes.addressesSegment}/${AppRoutes.newSegment}',
                builder: (context, _) => Scaffold(
                  body: TextButton(
                    onPressed: () => context.pop(true),
                    child: const Text('address form'),
                  ),
                ),
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
      return cartCubit;
    }

    Future<void> placeOrder(WidgetTester tester) async {
      final pay = find.byType(AppButton);
      await tester.scrollUntilVisible(pay, 200);
      await tester.tap(pay);
      await tester.pumpAndSettle();
    }

    testWidgets('placing opens the first order and rereads the cart',
        (tester) async {
      final cartCubit = await pumpCheckout(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Salmiya, 4, 12, 8, 3'), findsOneWidget);
      expect(cartCubit.state.status, CartStatus.loaded);

      network.replySample(
        'GET',
        ApiEndPoint.cart,
        'cart/cart_empty.cloak_shape.json',
      );
      await placeOrder(tester);

      expect(network.last('POST').data, {
        'address_id': 2,
        'payment_method': 'cash_on_delivery',
      });
      expect(find.text('order 41'), findsOneWidget);
      expect(cartCubit.state.cart?.isEmpty, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the order opens with the photos of the lines just bought',
        (tester) async {
      await pumpCheckout(tester);
      network.replySample(
        'GET',
        ApiEndPoint.cart,
        'cart/cart_empty.cloak_shape.json',
      );

      await placeOrder(tester);

      final photos = orderExtras.last! as Map<String, ImageRef>;
      expect(photos.keys, ['14']);
      expect(photos['14']?.url, 'https://images.example.com/maamoul.jpg');
    });

    testWidgets('a new customer adds an address and can then order',
        (tester) async {
      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: const {'success': true, 'data': []},
      );
      await pumpCheckout(tester);

      expect(find.text('checkout_no_address'.tr()), findsOneWidget);
      await tester.tap(find.text('address_add'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('address form'), findsOneWidget);

      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: {
          'success': true,
          'data': [_address(7, isDefault: true)],
        },
      );
      await tester.tap(find.text('address form'));
      await tester.pumpAndSettle();

      expect(find.text('Address 7'), findsOneWidget);
      await placeOrder(tester);

      expect(network.last('POST').data, {
        'address_id': 7,
        'payment_method': 'cash_on_delivery',
      });
      expect(tester.takeException(), isNull);
    });

    testWidgets('an answer that names no order opens the newest one',
        (tester) async {
      network.reply(
        'POST',
        ApiEndPoint.checkout,
        body: const {
          'success': true,
          'message': 'Order placed.',
          'data': null,
        },
      );
      await pumpCheckout(tester);

      await placeOrder(tester);

      expect(find.text('order latest'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
