import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/paged.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/services/network_service.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/orders/data/datasources/orders_data_source.dart';
import 'package:baytoti/features/orders/data/models/order_models.dart';
import 'package:baytoti/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:baytoti/features/orders/domain/entities/order.dart';
import 'package:baytoti/features/orders/domain/repositories/orders_repository.dart';
import 'package:baytoti/features/orders/domain/usecases/orders_usecases.dart';
import 'package:baytoti/features/orders/presentation/cubit/order_cubit.dart';
import 'package:baytoti/features/orders/presentation/cubit/order_state.dart';
import 'package:baytoti/features/orders/presentation/pages/order_page.dart';
import 'package:baytoti/features/orders/presentation/widgets/order_header_card.dart';
import 'package:baytoti/features/orders/presentation/widgets/order_items_section.dart';
import 'package:baytoti/features/orders/presentation/widgets/order_rating_card.dart';
import 'package:baytoti/features/orders/presentation/widgets/order_timeline.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
  Map<String, dynamic>? queryParameters;

  _RecordingNetwork({this.statusCode = 200, this.body = const {}});

  Response<dynamic> _answer(String url) => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        statusCode: statusCode,
        data: body,
      );

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async {
    this.url = url;
    this.queryParameters = queryParameters;
    return _answer(url);
  }

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
    return _answer(url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrdersRepository implements OrdersRepository {
  Either<Failure, Paged<OrderSummary>> orders =
      const Right(Paged<OrderSummary>());
  Either<Failure, OrderDetail>? order;
  Either<Failure, Unit> rating = const Right(unit);
  final List<String> requested = [];

  @override
  Future<Either<Failure, Paged<OrderSummary>>> getOrders(
    OrdersQuery query,
  ) async =>
      orders;

  @override
  Future<Either<Failure, OrderDetail>> getOrder(String id) async {
    requested.add(id);
    return order!;
  }

  @override
  Future<Either<Failure, Unit>> rateOrder(RateOrderParams params) async =>
      rating;
}

OrderCubit _cubitOver(OrdersRepository repository) => OrderCubit(
      GetOrdersUseCase(repository),
      GetOrderUseCase(repository),
      RateOrderUseCase(repository),
    );

OrdersRepository _fixtureRepository([FixtureBackend? backend]) =>
    OrdersRepositoryImpl(
      OrdersMockDataSource(backend ?? _InstantBackend(), () async => 'en'),
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
    test('an order reads its timeline, items, totals and flags', () {
      final order = OrderDetailModel.fromJson(
        _InstantBackend().order('ord_2041', 'en'),
      );

      expect(order.id, 'ord_2041');
      expect(order.reference, 'BT-2041');
      expect(order.status, OrderStatus.preparing);
      expect(order.etaDisplay, isNotEmpty);
      expect(order.timeline, hasLength(5));
      expect(
        order.timeline.map((s) => s.done),
        [true, true, true, false, false],
      );
      expect(order.timeline.first.status, OrderStatus.placed);
      expect(order.timeline.first.atDisplay, '10:04');
      expect(order.timeline.last.atDisplay, isNull);
      expect(order.timeline[3].status, OrderStatus.outForDelivery);
      expect(order.items, hasLength(2));
      expect(order.items.first.productId, 'prd_1');
      expect(order.items.first.lineTotalDisplay, '4.250 KWD');
      expect(order.items.last.quantity, 2);
      expect(order.totals.total.fils, 9050);
      expect(order.family?.id, 'fam_1');
      expect(order.canRate, isFalse);
    });

    test('a delivered order can be rated', () {
      final order = OrderDetailModel.fromJson(
        _InstantBackend().order('ord_1998', 'en'),
      );

      expect(order.status, OrderStatus.delivered);
      expect(order.canRate, isTrue);
      expect(order.timeline.every((s) => s.done), isTrue);
    });

    test('the order list is a cursor page', () {
      final page = OrderSummaryModel.pageFrom(_InstantBackend().orders('en'));

      expect(page.items.map((o) => o.id), ['ord_2041', 'ord_1998']);
      expect(page.items.first.status, OrderStatus.preparing);
      expect(page.items.first.totalDisplay, isNotEmpty);
      expect(page.hasMore, isFalse);
    });

    test('an unknown status is not guessed', () {
      expect(OrderStatus.fromWire('lost'), isNull);
      expect(OrderStatus.fromWire('out_for_delivery'), OrderStatus.outForDelivery);
    });

    test('a query omits what it does not filter on', () {
      expect(const OrdersQuery().toQueryParameters(), isEmpty);
      expect(
        const OrdersQuery(status: OrderStatus.delivered, cursor: 'c2')
            .toQueryParameters(),
        {'status': 'delivered', 'cursor': 'c2'},
      );
    });
  });

  group('the remote data source', () {
    test('lists orders with the query it was given', () async {
      final network = _RecordingNetwork(
        body: {
          'items': [
            {
              'id': 'ord_7',
              'reference': 'BT-7',
              'status': 'ready',
              'total_display': '1.000 KWD',
            },
          ],
          'next_cursor': 'n2',
        },
      );

      final result = await OrdersRemoteDataSource(network)
          .getOrders(const OrdersQuery(status: OrderStatus.ready));

      expect(network.url, ApiEndPoint.orders);
      expect(network.queryParameters, {'status': 'ready'});
      final page = result.getOrElse(() => throw StateError('failed'));
      expect(page.items.single.status, OrderStatus.ready);
      expect(page.nextCursor, 'n2');
    });

    test('a missing order reads as not found', () async {
      final network = _RecordingNetwork(
        statusCode: 404,
        body: {
          'error': {'code': 'not_found', 'message': ''},
        },
      );

      final result = await OrdersRemoteDataSource(network).getOrder('ord_x');

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect(failure?.message, 'order_not_found');
      expect(failure?.statusCode, 404);
    });

    test('a rating posts the stars', () async {
      final network = _RecordingNetwork(statusCode: 204, body: null);

      final result = await OrdersRemoteDataSource(network).rateOrder(
        const RateOrderParams(orderId: 'ord_1998', rating: 5),
      );

      expect(result, const Right<Failure, Unit>(unit));
      expect(network.url, ApiEndPoint.orderRating('ord_1998'));
      expect(network.data, {'rating': 5});
    });
  });

  group('the fixture repository', () {
    test('an unknown order is a not-found failure', () async {
      final result = await _fixtureRepository().getOrder('ord_404');

      final failure = result.fold((f) => f, (_) => null);
      expect(failure?.message, 'order_not_found');
      expect(failure?.code, 'not_found');
    });

    test('an order still in progress refuses a rating', () async {
      final result = await _fixtureRepository().rateOrder(
        const RateOrderParams(orderId: 'ord_2041', rating: 4),
      );

      expect(result.fold((f) => f.code, (_) => null), 'rating_unavailable');
    });

    test('rating a delivered order closes its rating', () async {
      final repository = _fixtureRepository();

      final rated = await repository.rateOrder(
        const RateOrderParams(orderId: 'ord_1998', rating: 5),
      );
      final order = await repository.getOrder('ord_1998');

      expect(rated.isRight(), isTrue);
      expect(order.fold((_) => null, (o) => o.canRate), isFalse);
    });
  });

  group('OrderCubit', () {
    test('loads the order it was opened on', () async {
      final cubit = _cubitOver(_fixtureRepository());

      await cubit.load('ord_2041');

      expect(cubit.state.status, OrderViewStatus.loaded);
      expect(cubit.state.order?.reference, 'BT-2041');
      expect(cubit.state.showsRating, isFalse);
    });

    test('resolves "latest" to the newest order', () async {
      final cubit = _cubitOver(_fixtureRepository());

      await cubit.load(OrderCubit.latest);

      expect(cubit.state.status, OrderViewStatus.loaded);
      expect(cubit.state.order?.id, 'ord_2041');
    });

    test('"latest" with no orders is empty, not an error', () async {
      final repository = _FakeOrdersRepository();
      final cubit = _cubitOver(repository);

      await cubit.load(OrderCubit.latest);

      expect(cubit.state.status, OrderViewStatus.empty);
      expect(repository.requested, isEmpty);
    });

    test('a failed first read is an error screen', () async {
      final repository = _FakeOrdersRepository()
        ..order = const Left(ServerFailure(message: 'order_failed'));
      final cubit = _cubitOver(repository);

      await cubit.load('ord_1');

      expect(cubit.state.status, OrderViewStatus.error);
      expect(cubit.state.errorMessage, 'order_failed');
    });

    test('a failed list read for "latest" is an error screen', () async {
      final repository = _FakeOrdersRepository()
        ..orders = const Left(NetworkFailure(message: 'offline'));
      final cubit = _cubitOver(repository);

      await cubit.load(OrderCubit.latest);

      expect(cubit.state.status, OrderViewStatus.error);
      expect(cubit.state.errorMessage, 'offline');
    });

    test('rating a delivered order succeeds and hides the card', () async {
      final cubit = _cubitOver(_fixtureRepository());
      await cubit.load('ord_1998');
      expect(cubit.state.showsRating, isTrue);

      await cubit.rate(4);

      expect(cubit.state.ratingStatus, RatingStatus.succeeded);
      expect(cubit.state.order?.canRate, isFalse);
      expect(cubit.state.showsRating, isFalse);
    });

    test('a refused rating keeps the card and reports why', () async {
      final repository = _FakeOrdersRepository()
        ..order = Right(OrderDetailModel.fromJson(
          _InstantBackend().order('ord_1998', 'en'),
        ))
        ..rating = const Left(ServerFailure(message: 'rating_failed'));
      final cubit = _cubitOver(repository);
      await cubit.load('ord_1998');

      await cubit.rate(3);

      expect(cubit.state.ratingStatus, RatingStatus.failed);
      expect(cubit.state.rating, 0);
      expect(cubit.state.errorMessage, 'rating_failed');
      expect(cubit.state.showsRating, isTrue);
    });

    test('an order that cannot be rated ignores a star', () async {
      final repository = _FakeOrdersRepository()
        ..order = Right(OrderDetailModel.fromJson(
          _InstantBackend().order('ord_2041', 'en'),
        ))
        ..rating = const Left(ServerFailure(message: 'rating_failed'));
      final cubit = _cubitOver(repository);
      await cubit.load('ord_2041');

      await cubit.rate(5);

      expect(cubit.state.ratingStatus, RatingStatus.idle);
      expect(cubit.state.errorMessage, isNull);
    });

    test('a failed refresh keeps the order on screen', () async {
      final repository = _FakeOrdersRepository()
        ..order = Right(OrderDetailModel.fromJson(
          _InstantBackend().order('ord_2041', 'en'),
        ));
      final cubit = _cubitOver(repository);
      await cubit.load('ord_2041');

      repository.order = const Left(NetworkFailure(message: 'offline'));
      await cubit.refresh();

      expect(cubit.state.status, OrderViewStatus.loaded);
      expect(cubit.state.order?.id, 'ord_2041');
      expect(cubit.state.errorMessage, 'offline');
    });
  });

  group('widgets', () {
    testWidgets('the tracking sections lay out and a star rates',
        (tester) async {
      final order = OrderDetailModel.fromJson(
        _InstantBackend().order('ord_1998', 'en'),
      );
      final ratings = <int>[];

      await tester.pumpWidget(_app(SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderHeaderCard(reference: order.reference, eta: order.etaDisplay),
            OrderTimeline(steps: order.timeline),
            OrderItemsSection(
              items: order.items,
              totalDisplay: order.totals.total.display,
            ),
            OrderRatingCard(rating: 2, enabled: true, onRate: ratings.add),
          ],
        ),
      )));

      expect(find.text('BT-1998'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('× 2'), findsOneWidget);

      final fourth = find
          .descendant(
            of: find.byType(OrderRatingCard),
            matching: find.byType(InkWell),
          )
          .at(3);
      await tester.ensureVisible(fourth);
      await tester.tap(fourth);
      expect(ratings, [4]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pending step reads as pending', (tester) async {
      await tester.pumpWidget(_app(const OrderTimeline(
        steps: [
          OrderTimelineStep(label: 'Received', atDisplay: '10:04', done: true),
          OrderTimelineStep(label: 'Delivered', done: false),
        ],
      )));

      expect(find.text('10:04'), findsOneWidget);
      expect(find.text('order_pending'), findsOneWidget);
    });
  });

  group('the order page', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    tearDown(() => GetIt.instance.reset());

    Future<void> pumpOrderPage(WidgetTester tester, String orderId) async {
      final repository = _fixtureRepository();
      GetIt.instance.registerFactory(() => _cubitOver(repository));

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

      expect(find.text('BT-2041'), findsOneWidget);
      expect(find.text('Pending'), findsNWidgets(2));
      expect(find.byType(OrderRatingCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a star rates a delivered order and the card goes',
        (tester) async {
      await pumpOrderPage(tester, 'ord_1998');

      await tester.scrollUntilVisible(find.byType(OrderRatingCard), 200);
      await tester.tap(find
          .descendant(
            of: find.byType(OrderRatingCard),
            matching: find.byType(InkWell),
          )
          .last);
      await tester.pumpAndSettle();

      expect(find.text('Thank you for your rating'), findsOneWidget);
      expect(find.byType(OrderRatingCard), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
