import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/domain/entities/order_totals.dart';
import 'package:baytoti/features/orders/data/datasources/orders_data_source.dart';
import 'package:baytoti/features/orders/data/models/order_models.dart';
import 'package:baytoti/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:baytoti/features/orders/domain/entities/order.dart';
import 'package:baytoti/features/orders/domain/usecases/orders_usecases.dart';
import 'package:baytoti/features/orders/presentation/cubit/order_cubit.dart';
import 'package:baytoti/features/orders/presentation/cubit/order_state.dart';
import 'package:baytoti/features/orders/presentation/pages/order_page.dart';
import 'package:baytoti/features/orders/presentation/widgets/order_header_card.dart';
import 'package:baytoti/features/orders/presentation/widgets/order_items_section.dart';
import 'package:baytoti/features/orders/presentation/widgets/order_timeline.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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

const OrderTotals _noMoney = OrderTotals(
  subtotal: Money(fils: 0),
  discount: Money(fils: 0),
  shipping: Money(fils: 0),
  total: Money(fils: 0),
);

final DateTime _placed = DateTime.utc(2026, 5, 12, 10, 4).toLocal();
final DateTime _changed = DateTime.utc(2026, 5, 12, 13, 30).toLocal();

OrderDetail _detail(OrderStatus? status) => OrderDetail(
      id: '12',
      reference: 'ORD-2026-1258',
      status: status,
      items: const [],
      totals: _noMoney,
      createdAt: _placed,
      updatedAt: _changed,
    );

T _valueOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('refused: $result'));

Failure _failureOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => throw StateError('succeeded'));

OrderCubit _cubitOver(FakeNetwork network) {
  final repository = OrdersRepositoryImpl(OrdersRemoteDataSource(network));
  return OrderCubit(
    GetOrdersUseCase(repository),
    GetOrderUseCase(repository),
    CancelOrderUseCase(repository),
  );
}

Map<String, dynamic> _orderBody(String status) => {
      'success': true,
      'data': {'id': 12, 'order_number': 'ORD-2026-1258', 'status': status},
    };

const Map<String, dynamic> _cancelRefused = {
  'success': false,
  'message': 'لا يمكن إلغاء الطلب بعد تأكيده.',
  'data': '',
};

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
  late OrdersRemoteDataSource source;

  setUp(() {
    network = FakeNetwork()
      ..replySample(
        'GET',
        ApiEndPoint.orders,
        'orders/orders_page.cloak_shape.json',
      )
      ..replySample(
        'GET',
        ApiEndPoint.order('12'),
        'orders/order_detail.cloak_shape.json',
      );
    source = OrdersRemoteDataSource(network);
  });

  group('the cloak order shape', () {
    test('an order reads its number, store, lines, money and dates',
        () async {
      final order = _valueOf(await source.getOrder('12'));

      expect(order.id, '12');
      expect(order.reference, 'ORD-2026-1258');
      expect(order.status, OrderStatus.processing);
      expect(order.family?.name, 'مطبخ أم عبدالله');
      expect(order.items.map((l) => l.name), ['مجبوس دجاج', 'معمول تمر']);
      expect(order.items.first.productId, '26');
      expect(order.items.last.quantity, 2);
      expect(order.items.last.unitPrice.fils, 16000);
      expect(order.items.last.lineTotal.fils, 32000);
      expect(order.totals.subtotal.fils, 70000);
      expect(order.totals.discount.fils, 0);
      expect(order.totals.shipping.fils, 2000);
      expect(order.totals.total.fils, 72000);
      expect(order.createdAt, _placed);
      expect(order.updatedAt, _changed);
    });

    test('a total the server leaves out is derived from its parts', () {
      final order = OrderDetailModel.fromJson(const {
        'id': 3,
        'order_number': 'ORD-2026-0003',
        'financials': {
          'subtotal': '10.000',
          'discount': '1.000',
          'shipping_fee': '2.000',
        },
      });

      expect(order.totals.total.fils, 11000);
      expect(order.items, isEmpty);
      expect(order.family, isNull);
    });

    test('the six statuses read as themselves, anything else as unknown', () {
      for (final status in OrderStatus.values) {
        expect(OrderStatus.fromWire(status.wire), status);
      }
      expect(OrderStatus.fromWire(' Processing '), OrderStatus.processing);
      expect(OrderStatus.fromWire('out_for_delivery'), isNull);
      expect(OrderStatus.fromWire(null), isNull);
    });

    test('an order can be cancelled until the family starts preparing it',
        () {
      expect(
        OrderStatus.values.where((status) => status.isCancellable),
        [OrderStatus.pending, OrderStatus.confirmed],
      );
      expect(OrderState(order: _detail(null)).canCancel, isFalse);
      expect(const OrderState().canCancel, isFalse);
    });

    test('the list pages by meta', () async {
      final page = _valueOf(await source.getOrders(const OrdersQuery()));

      expect(page.items.map((o) => o.id), ['12', '9']);
      expect(page.items.first.reference, 'ORD-2026-1258');
      expect(page.items.first.status, OrderStatus.processing);
      expect(page.items.first.total.fils, 72000);
      expect(page.items.last.family?.name, 'حلويات نورة');
      expect(page.currentPage, 1);
      expect(page.lastPage, 2);
      expect(page.total, 17);
      expect(page.hasMore, isTrue);
    });

    test('a row without an id is dropped: there is nothing to open', () {
      final page = OrderSummaryModel.pageFrom(const {
        'data': [
          {'order_number': 'ORD-X', 'status': 'pending'},
          {'id': 5, 'order_number': 'ORD-2026-0005', 'status': 'pending'},
        ],
      });

      expect(page.items.map((o) => o.id), ['5']);
    });
  });

  group('the timeline', () {
    test('a processing order has reached three of five steps', () {
      final steps = _detail(OrderStatus.processing).timeline;

      expect(steps.map((s) => s.status), OrderStatus.flow);
      expect(steps.map((s) => s.done), [true, true, true, false, false]);
      expect(steps.map((s) => s.at), [_placed, null, _changed, null, null]);
    });

    test('a pending order shows only when it was placed', () {
      final steps = _detail(OrderStatus.pending).timeline;

      expect(steps.map((s) => s.done), [true, false, false, false, false]);
      expect(steps.map((s) => s.at), [_placed, null, null, null, null]);
    });

    test('a delivered order has done every step', () {
      final steps = _detail(OrderStatus.delivered).timeline;

      expect(steps.every((s) => s.done), isTrue);
      expect(steps.last.at, _changed);
    });

    test('a cancelled order replaces the rest of the flow', () {
      final steps = _detail(OrderStatus.cancelled).timeline;

      expect(steps.map((s) => s.status), OrderStatus.cancelledFlow);
      expect(steps.map((s) => s.done), [true, true]);
      expect(steps.map((s) => s.at), [_placed, _changed]);
    });

    test('an unknown status reads as the first step', () {
      expect(_detail(null).timeline, _detail(OrderStatus.pending).timeline);
    });
  });

  group('the remote data source', () {
    test('the first page is asked for with nothing added', () async {
      await source.getOrders(const OrdersQuery());

      expect(network.last('GET').url, ApiEndPoint.orders);
      expect(network.last('GET').query, isEmpty);
    });

    test('a later page names its number', () async {
      await source.getOrders(const OrdersQuery(page: 2));

      expect(network.last('GET').query, {'page': 2});
    });

    test('an order is read by its id', () async {
      await source.getOrder('12');

      expect(network.last('GET').url, ApiEndPoint.order('12'));
    });

    test('an unknown order is a readable not-found', () async {
      network.replySample(
        'GET',
        ApiEndPoint.order('999999999'),
        'orders/order_404.cloak_shape.json',
        status: 404,
      );

      final failure = _failureOf(await source.getOrder('999999999'));

      expect(failure.statusCode, 404);
      expect(failure.message, 'order_not_found');
    });

    test('an answer that carries no order is not-found too', () async {
      network.reply(
        'GET',
        ApiEndPoint.order('7'),
        body: const {'success': true, 'message': 'ok', 'data': null},
      );

      final failure = _failureOf(await source.getOrder('7'));

      expect(failure.message, 'order_not_found');
    });

    test('an order nested under data.order is read', () async {
      network.reply(
        'GET',
        ApiEndPoint.order('7'),
        body: const {
          'success': true,
          'data': {
            'order': {
              'id': 7,
              'order_number': 'ORD-2026-0007',
              'status': 'shipped',
            },
          },
        },
      );

      final order = _valueOf(await source.getOrder('7'));

      expect(order.reference, 'ORD-2026-0007');
      expect(order.status, OrderStatus.shipped);
    });

    test('without a token the orders are a 401', () async {
      network.replySample(
        'GET',
        ApiEndPoint.orders,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      final failure = _failureOf(await source.getOrders(const OrdersQuery()));

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
    });

    test('a server error shows the generic message', () async {
      network.replySample(
        'GET',
        ApiEndPoint.order('12'),
        'betouti/products_guest_500.json',
        status: 500,
      );

      expect(_failureOf(await source.getOrder('12')).message, 'server_error');
    });

    test('a cancel is a PATCH that reads the order it answers', () async {
      network.reply(
        'PATCH',
        ApiEndPoint.cancelOrder('12'),
        body: _orderBody('cancelled'),
      );

      final order = _valueOf(await source.cancelOrder('12'));

      expect(order.status, OrderStatus.cancelled);
      expect(network.calls.map((c) => '${c.method} ${c.url}'), [
        'PATCH ${ApiEndPoint.cancelOrder('12')}',
      ]);
    });

    test('a cancel that answers no order reads it back', () async {
      network
        ..reply(
          'PATCH',
          ApiEndPoint.cancelOrder('12'),
          body: const {'success': true, 'message': 'cancelled', 'data': null},
        )
        ..reply('GET', ApiEndPoint.order('12'), body: _orderBody('cancelled'));

      final order = _valueOf(await source.cancelOrder('12'));

      expect(order.status, OrderStatus.cancelled);
      expect(network.calls.map((c) => c.method), ['PATCH', 'GET']);
    });

    test('a refused cancel carries the server reason', () async {
      network.reply(
        'PATCH',
        ApiEndPoint.cancelOrder('12'),
        status: 422,
        body: _cancelRefused,
      );

      final failure = _failureOf(await source.cancelOrder('12'));

      expect(failure.message, _cancelRefused['message']);
    });

    test('offline is a network failure', () async {
      final offline = OrdersRemoteDataSource(_OfflineNetwork());

      expect(
        _failureOf(await offline.getOrders(const OrdersQuery())),
        isA<NetworkFailure>(),
      );
    });
  });

  group('OrderCubit', () {
    test('"latest" opens the first row of the first page', () async {
      final cubit = _cubitOver(network);
      addTearDown(cubit.close);

      await cubit.load(OrderCubit.latest);

      expect(network.calls.map((c) => c.url), [
        ApiEndPoint.orders,
        ApiEndPoint.order('12'),
      ]);
      expect(cubit.state.status, OrderViewStatus.loaded);
      expect(cubit.state.order?.reference, 'ORD-2026-1258');
    });

    test('no orders at all is the empty state', () async {
      network.reply(
        'GET',
        ApiEndPoint.orders,
        body: const {
          'success': true,
          'data': [],
          'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
        },
      );
      final cubit = _cubitOver(network);
      addTearDown(cubit.close);

      await cubit.load(OrderCubit.latest);

      expect(cubit.state.status, OrderViewStatus.empty);
      expect(network.calls, hasLength(1));
    });

    test('a failed first read is an error screen that a retry clears',
        () async {
      network.replySample(
        'GET',
        ApiEndPoint.order('12'),
        'betouti/products_guest_500.json',
        status: 500,
      );
      final cubit = _cubitOver(network);
      addTearDown(cubit.close);

      await cubit.load('12');
      expect(cubit.state.status, OrderViewStatus.error);
      expect(cubit.state.errorMessage, 'server_error');

      network.replySample(
        'GET',
        ApiEndPoint.order('12'),
        'orders/order_detail.cloak_shape.json',
      );
      await cubit.refresh();

      expect(cubit.state.status, OrderViewStatus.loaded);
      expect(cubit.state.errorMessage, isNull);
    });

    test('a failed refresh keeps the order on screen', () async {
      final cubit = _cubitOver(network);
      addTearDown(cubit.close);
      await cubit.load('12');

      network.replySample(
        'GET',
        ApiEndPoint.order('12'),
        'betouti/unauthenticated_401.json',
        status: 401,
      );
      await cubit.refresh();

      expect(cubit.state.status, OrderViewStatus.loaded);
      expect(cubit.state.order?.id, '12');
      expect(cubit.state.errorMessage, 'Unauthenticated.');
    });

    test('cancelling a pending order shows it cancelled', () async {
      network
        ..reply('GET', ApiEndPoint.order('12'), body: _orderBody('pending'))
        ..reply(
          'PATCH',
          ApiEndPoint.cancelOrder('12'),
          body: _orderBody('cancelled'),
        );
      final cubit = _cubitOver(network);
      addTearDown(cubit.close);
      await cubit.load('12');
      expect(cubit.state.canCancel, isTrue);

      final cancelling = cubit.cancel();
      expect(cubit.state.isCancelling, isTrue);
      await cancelling;

      expect(cubit.state.order?.status, OrderStatus.cancelled);
      expect(cubit.state.canCancel, isFalse);
      expect(cubit.state.isCancelling, isFalse);
    });

    test('a refused cancel keeps the order and says why', () async {
      network
        ..reply('GET', ApiEndPoint.order('12'), body: _orderBody('pending'))
        ..reply(
          'PATCH',
          ApiEndPoint.cancelOrder('12'),
          status: 422,
          body: _cancelRefused,
        );
      final cubit = _cubitOver(network);
      addTearDown(cubit.close);
      await cubit.load('12');

      await cubit.cancel();

      expect(cubit.state.order?.status, OrderStatus.pending);
      expect(cubit.state.isCancelling, isFalse);
      expect(cubit.state.errorMessage, _cancelRefused['message']);
    });

    test('an order already being prepared is never sent a cancel', () async {
      final cubit = _cubitOver(network);
      addTearDown(cubit.close);
      await cubit.load('12');

      await cubit.cancel();

      expect(network.calls.where((c) => c.method == 'PATCH'), isEmpty);
    });
  });

  group('widgets', () {
    testWidgets('the tracking sections lay out the server order',
        (tester) async {
      final order = _valueOf(await source.getOrder('12'));

      await tester.pumpWidget(_app(SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderHeaderCard(
              reference: order.reference,
              subtitle: order.family?.name,
            ),
            OrderTimeline(steps: order.timeline),
            OrderItemsSection(
              items: order.items,
              totalDisplay: order.totals.total.display,
            ),
          ],
        ),
      )));

      expect(find.text('ORD-2026-1258'), findsOneWidget);
      expect(find.text('مطبخ أم عبدالله'), findsOneWidget);
      expect(find.text('order_status_processing'), findsOneWidget);
      expect(find.text(OrderTimeline.formatAt(_placed)), findsOneWidget);
      expect(find.text(OrderTimeline.formatAt(_changed)), findsOneWidget);
      expect(find.text('order_pending'), findsNWidgets(2));
      expect(find.text('× 2'), findsOneWidget);
      expect(find.text(const Money(fils: 72000).display), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a cancelled order draws two steps', (tester) async {
      await tester.pumpWidget(_app(OrderTimeline(
        steps: _detail(OrderStatus.cancelled).timeline,
      )));

      expect(find.text('order_status_pending'), findsOneWidget);
      expect(find.text('order_status_cancelled'), findsOneWidget);
      expect(find.text('order_status_delivered'), findsNothing);
      expect(find.text('order_pending'), findsNothing);
    });
  });

  group('the order page', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    tearDown(() => GetIt.instance.reset());

    Future<void> pumpOrderPage(WidgetTester tester, String orderId) async {
      GetIt.instance.registerFactory(() => _cubitOver(network));

      await tester.runAsync(() async {
        await tester.pumpWidget(EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          saveLocale: false,
          child: Builder(
            builder: (context) => ScreenUtilScope(
              child: Builder(
                builder: (_) => MaterialApp(
                  theme: AppTheme.light,
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: OrderPage(orderId: orderId),
                ),
              ),
            ),
          ),
        ));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
    }

    testWidgets('"latest" opens the newest order', (tester) async {
      await pumpOrderPage(tester, OrderPage.latest);

      expect(find.text('ORD-2026-1258'), findsOneWidget);
      expect(find.text('مجبوس دجاج'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an order already being prepared has no cancel button',
        (tester) async {
      await pumpOrderPage(tester, '12');

      expect(find.text('ORD-2026-1258'), findsOneWidget);
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('a pending order is cancelled once the customer confirms',
        (tester) async {
      network
        ..reply('GET', ApiEndPoint.order('12'), body: _orderBody('pending'))
        ..reply(
          'PATCH',
          ApiEndPoint.cancelOrder('12'),
          body: _orderBody('cancelled'),
        );
      await pumpOrderPage(tester, '12');

      await tester.ensureVisible(find.text('Cancel order'));
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsOneWidget);
      expect(network.calls.where((c) => c.method == 'PATCH'), isEmpty);

      await tester.tap(find.text('Cancel order').last);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(network.calls.where((c) => c.method == 'PATCH'), hasLength(1));
      expect(find.text('Cancel order'), findsNothing);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unknown order says so and offers a retry',
        (tester) async {
      network.replySample(
        'GET',
        ApiEndPoint.order('999999999'),
        'orders/order_404.cloak_shape.json',
        status: 404,
      );

      await pumpOrderPage(tester, '999999999');

      expect(find.text('This order could not be found.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
