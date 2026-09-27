import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_palette.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/notifications/data/datasources/notifications_data_source.dart';
import 'package:baytoti/features/notifications/data/models/notification_model.dart';
import 'package:baytoti/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:baytoti/features/notifications/domain/entities/app_notification.dart';
import 'package:baytoti/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:baytoti/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:baytoti/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:baytoti/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

const String _page1 = 'notifications/page_1.cloak_shape.json';
const String _page2 = 'notifications/page_2.cloak_shape.json';
const String _readAll = 'notifications/read_all.cloak_shape.json';

class _FeedNetwork extends FakeNetwork {
  final Map<int, (int, Object?)> pages = {};
  final Map<int, Completer<void>> gates = {};
  bool offline = false;

  void page(int number, String sample, {int status = 200}) =>
      pages[number] = (status, apiSample(sample));

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async {
    if (offline) throw const ConnectionException();
    final number = queryParameters?['page'] as int? ?? 1;
    final gate = gates[number];
    if (gate != null) await gate.future;
    final answer = pages[number];
    if (answer != null) reply('GET', url, status: answer.$1, body: answer.$2);
    return super.get(
      url,
      queryParameters: queryParameters,
      headers: headers,
      skipAuthRefresh: skipAuthRefresh,
    );
  }

  @override
  Future<Response> patch(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async {
    if (offline) throw const ConnectionException();
    return super.patch(
      url,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      skipAuthRefresh: skipAuthRefresh,
    );
  }

  List<FakeCall> of(String method) =>
      calls.where((call) => call.method == method).toList();
}

Map<String, dynamic> _row(Map<String, dynamic> overrides) => {
      'id': 'ntf-1',
      'type': 'order_status_changed',
      'title': 'Title',
      'body': 'Body',
      'data': {'entity': null, 'entity_id': null, 'action': null},
      'read_at': null,
      'created_at': '2026-09-12T20:15:00.000000Z',
      ...overrides,
    };

Map<String, dynamic> _feed(List<Map<String, dynamic>> rows, {int last = 1}) =>
    {
      'success': true,
      'message': 'Notifications retrieved successfully.',
      'data': rows,
      'meta': {'current_page': 1, 'last_page': last, 'per_page': 15},
      'errors': null,
    };

AppNotification _parse(Map<String, dynamic> overrides) =>
    NotificationModel.fromJson(_row(overrides));

T _right<T>(Either<Failure, T> result) =>
    result.fold((failure) => throw StateError('$failure'), (value) => value);

Failure _left<T>(Either<Failure, T> result) =>
    result.fold((failure) => failure, (value) => throw StateError('$value'));

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FeedNetwork network;
  late NotificationsRepositoryImpl repository;

  NotificationsCubit cubit() => NotificationsCubit(
        GetNotificationsUseCase(repository),
        MarkNotificationsReadUseCase(repository),
      );

  setUp(() {
    network = _FeedNetwork()
      ..page(1, _page1)
      ..page(2, _page2)
      ..replySample('PATCH', ApiEndPoint.markNotificationsRead, _readAll);
    repository =
        NotificationsRepositoryImpl(NotificationsRemoteDataSource(network));
  });

  group('the feed as cloak sends it', () {
    test('a page reads its rows and its position from meta', () {
      final page = NotificationModel.pageFrom(
        Map<String, dynamic>.from(apiSample(_page1) as Map),
      );

      expect(page.items.map((n) => n.id), [
        '9d2f6c1e-0b7a-4e57-9f0e-1b2c3d4e5f60',
        '3b1a0f7d-5c2e-4d8a-9b6f-7e8d9c0a1b2c',
        '6e4c2a0b-8f1d-4b3e-a5c7-d9e0f1a2b3c4',
      ]);
      expect(page.currentPage, 1);
      expect(page.lastPage, 2);
      expect(page.total, 4);
      expect(page.hasMore, isTrue);
    });

    test('an order row is unread, typed and opens its order by id', () {
      final page = NotificationModel.pageFrom(
        Map<String, dynamic>.from(apiSample(_page1) as Map),
      );
      final order = page.items.first;

      expect(order.isRead, isFalse);
      expect(order.type, NotificationType.orderStatus);
      expect(order.headline, 'Your order has shipped');
      expect(order.detail, 'Order #ORD-2026-1258 is on its way.');
      expect(order.createdAt, DateTime.utc(2026, 9, 12, 20, 15));
      expect(
        order.target,
        const NotificationTarget(
          kind: NotificationTargetKind.order,
          handle: '42',
        ),
      );
    });

    test('a product row carrying only an id cannot be opened', () {
      final page = NotificationModel.pageFrom(
        Map<String, dynamic>.from(apiSample(_page1) as Map),
      );

      expect(page.items[1].type, NotificationType.familyUpdate);
      expect(page.items[1].target, isNull);
    });

    test('a row with no title leads with its body and is read', () {
      final page = NotificationModel.pageFrom(
        Map<String, dynamic>.from(apiSample(_page1) as Map),
      );
      final coupon = page.items[2];

      expect(coupon.type, NotificationType.offer);
      expect(coupon.title, isNull);
      expect(coupon.headline, 'Use BAYT10 for 10% off your next order.');
      expect(coupon.detail, isNull);
      expect(coupon.isRead, isTrue);
      expect(coupon.readAt, DateTime.utc(2026, 9, 10, 12));
      expect(coupon.target, isNull);
    });

    test('a product or store with a slug opens by that slug', () {
      expect(
        _parse({
          'data': {'entity': 'store', 'entity_id': 3, 'slug': 'umm-ali'},
        }).target,
        const NotificationTarget(
          kind: NotificationTargetKind.family,
          handle: 'umm-ali',
        ),
      );
      expect(
        _parse({
          'data': {'entity': 'product', 'entity_id': 9, 'slug': 'kunafa'},
        }).target,
        const NotificationTarget(
          kind: NotificationTargetKind.product,
          handle: 'kunafa',
        ),
      );
    });

    test('odd values are read leniently', () {
      final odd = _parse({
        'id': 7,
        'type': 'App\\Notifications\\Mystery',
        'title': '   ',
        'body': null,
        'data': const [],
        'read_at': 'not a date',
        'created_at': null,
      });

      expect(odd.id, '7');
      expect(odd.type, isNull);
      expect(odd.headline, isNull);
      expect(odd.isRead, isFalse);
      expect(odd.createdAt, isNull);
      expect(odd.target, isNull);
    });

    test('a title kept inside data is still shown', () {
      final nested = _parse({
        'title': null,
        'body': null,
        'data': {'title': 'Inside', 'body': 'data'},
      });

      expect(nested.headline, 'Inside');
      expect(nested.detail, 'data');
    });

    test('a row without an id is dropped, and a bare page is one page', () {
      final page = NotificationModel.pageFrom({
        'data': [
          _row({'id': null}),
          _row({'id': ''}),
          _row({'id': 'kept'}),
          'not a row',
        ],
      });

      expect(page.items.map((n) => n.id), ['kept']);
      expect(page.hasMore, isFalse);
    });

    test('the type follows the server words, most specific first', () {
      NotificationType? typeOf(String type, [String? action]) =>
          NotificationType.classify([type, action]);

      expect(
        typeOf('review_requested', 'order'),
        NotificationType.ratingRequest,
      );
      expect(typeOf('order_delivered'), NotificationType.orderStatus);
      expect(typeOf('exhibition_opening'), NotificationType.exhibition);
      expect(typeOf('support_reply'), NotificationType.support);
      expect(typeOf('store_new_dish'), NotificationType.familyUpdate);
      expect(typeOf('promo'), NotificationType.offer);
      expect(typeOf('something_else'), isNull);
      expect(NotificationType.classify(const [null]), isNull);
    });

    test('each type has its own tag key', () {
      expect(
        NotificationType.values.map((type) => type.tagKey).toSet(),
        {
          'notification_tag_order_status',
          'notification_tag_offer',
          'notification_tag_exhibition',
          'notification_tag_family_update',
          'notification_tag_rating_request',
          'notification_tag_support',
        },
      );
    });

    test('the query omits an absent page', () {
      expect(const NotificationsQuery().toQueryParameters(), isEmpty);
      expect(
        const NotificationsQuery(page: 2).toQueryParameters(),
        {'page': 2},
      );
    });
  });

  group('the remote source through the repository', () {
    test('the feed is a GET on notifications with the page asked for',
        () async {
      final first = _right(
        await repository.getNotifications(const NotificationsQuery()),
      );
      final second = _right(
        await repository.getNotifications(const NotificationsQuery(page: 2)),
      );

      expect(network.of('GET').map((c) => c.url), [
        ApiEndPoint.notifications,
        ApiEndPoint.notifications,
      ]);
      expect(network.of('GET').first.query, isEmpty);
      expect(network.of('GET').last.query, {'page': 2});
      expect(first.items, hasLength(3));
      expect(second.items.single.type, NotificationType.ratingRequest);
      expect(second.hasMore, isFalse);
    });

    test('marking all read is a PATCH on read-all, never a POST', () async {
      expect(await repository.markAllRead(), const Right<Failure, Unit>(unit));

      expect(network.last('PATCH').url, ApiEndPoint.markNotificationsRead);
      expect(network.of('POST'), isEmpty);
      expect(network.of('DELETE'), isEmpty);
    });

    test('a 401 is a server failure carrying its status', () async {
      network.page(1, 'betouti/unauthenticated_401.json', status: 401);

      final failure = _left(
        await repository.getNotifications(const NotificationsQuery()),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
    });

    test('a server crash never shows its exception text', () async {
      network.page(1, 'betouti/products_guest_500.json', status: 500);

      final failure = _left(
        await repository.getNotifications(const NotificationsQuery()),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 500);
      expect(failure.message, isNot(contains('LocationContextService')));
    });

    test('a refused read-all is a failure', () async {
      network.replySample(
        'PATCH',
        ApiEndPoint.markNotificationsRead,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      expect(_left(await repository.markAllRead()).statusCode, 401);
    });

    test('offline is a network failure for both calls', () async {
      network.offline = true;

      expect(
        _left(await repository.getNotifications(const NotificationsQuery())),
        isA<NetworkFailure>(),
      );
      expect(_left(await repository.markAllRead()), isA<NetworkFailure>());
    });
  });

  group('NotificationsCubit', () {
    test('a first page loads, then everything is marked read', () async {
      final notifications = cubit();
      final states = <NotificationsState>[];
      final sub = notifications.stream.listen(states.add);

      await notifications.load();
      await _settle();

      expect(states.map((s) => s.status), [
        NotificationsStatus.loading,
        NotificationsStatus.loaded,
      ]);
      expect(notifications.state.notifications, hasLength(3));
      expect(notifications.state.notifications.first.isRead, isFalse);
      expect(network.of('PATCH').single.url, ApiEndPoint.markNotificationsRead);

      await sub.cancel();
      await notifications.close();
    });

    test('nothing is marked read when nothing is unread', () async {
      network.pages[1] = (
        200,
        _feed([
          _row({'read_at': '2026-09-12T21:00:00.000000Z'}),
        ]),
      );
      final notifications = cubit();

      await notifications.load();
      await _settle();

      expect(notifications.state.notifications.single.isRead, isTrue);
      expect(network.of('PATCH'), isEmpty);
      await notifications.close();
    });

    test('a refused read-all leaves the list as it was', () async {
      network.replySample(
        'PATCH',
        ApiEndPoint.markNotificationsRead,
        'betouti/products_guest_500.json',
        status: 500,
      );
      final notifications = cubit();

      await notifications.load();
      await _settle();

      expect(notifications.state.isLoaded, isTrue);
      expect(notifications.state.notifications, hasLength(3));
      await notifications.close();
    });

    test('a failed first read is an error screen', () async {
      network.page(1, 'betouti/unauthenticated_401.json', status: 401);
      final notifications = cubit();

      await notifications.load();

      expect(notifications.state.status, NotificationsStatus.error);
      expect(notifications.state.errorMessage, 'Unauthenticated.');
      expect(network.of('PATCH'), isEmpty);
      await notifications.close();
    });

    test('a failed refresh keeps the list', () async {
      final notifications = cubit();
      await notifications.load();

      network.offline = true;
      await notifications.load();

      expect(notifications.state.status, NotificationsStatus.loaded);
      expect(notifications.state.notifications, hasLength(3));
      expect(notifications.state.errorMessage, 'connection_failed');
      await notifications.close();
    });

    test('two loads at once send one request', () async {
      final notifications = cubit();

      await Future.wait([notifications.load(), notifications.load()]);

      expect(network.of('GET'), hasLength(1));
      expect(notifications.state.isLoaded, isTrue);
      await notifications.close();
    });

    test('the next page is read by page number and appended', () async {
      final notifications = cubit();
      await notifications.load();

      await notifications.loadMore();

      expect(network.of('GET').last.query, {'page': 2});
      expect(notifications.state.notifications, hasLength(4));
      expect(
        notifications.state.notifications.last.id,
        '0a9b8c7d-6e5f-4a3b-2c1d-0e9f8a7b6c5d',
      );
      expect(notifications.state.page.hasMore, isFalse);
      expect(notifications.state.isLoadingMore, isFalse);

      await notifications.loadMore();
      expect(network.of('GET'), hasLength(2));
      await notifications.close();
    });

    test('a failed next page keeps the list', () async {
      network.page(2, 'betouti/products_guest_500.json', status: 500);
      final notifications = cubit();
      await notifications.load();

      await notifications.loadMore();

      expect(notifications.state.status, NotificationsStatus.loaded);
      expect(notifications.state.notifications, hasLength(3));
      expect(notifications.state.page.lastPage, 2);
      expect(notifications.state.isLoadingMore, isFalse);
      expect(notifications.state.errorMessage, 'server_error');
      await notifications.close();
    });

    test('a page that lands after a refresh is dropped', () async {
      final notifications = cubit();
      await notifications.load();

      final gate = network.gates[2] = Completer<void>();
      final more = notifications.loadMore();
      network.pages[1] = (200, _feed([_row({'id': 'fresh'})], last: 3));
      await notifications.load();
      gate.complete();
      await more;

      expect(notifications.state.notifications.map((n) => n.id), ['fresh']);
      expect(notifications.state.page.lastPage, 3);
      expect(notifications.state.isLoadingMore, isFalse);
      await notifications.close();
    });
  });

  group('the time a row prints', () {
    final now = DateTime(2026, 9, 27, 18);

    test('today is the clock time', () {
      expect(
        notificationTimeLabel(DateTime(2026, 9, 27, 9, 5), now: now),
        '09:05',
      );
    });

    test('earlier this year is day and month', () {
      expect(
        notificationTimeLabel(DateTime(2026, 9, 12, 20, 15), now: now),
        '12/9',
      );
    });

    test('another year adds the year', () {
      expect(
        notificationTimeLabel(DateTime(2025, 12, 30, 17, 45), now: now),
        '30/12/2025',
      );
    });
  });

  group('NotificationTile', () {
    Future<void> pumpTile(
      WidgetTester tester,
      AppNotification notification, {
      VoidCallback? onTap,
    }) =>
        tester.pumpWidget(ScreenUtilScope(
          child: Builder(
            builder: (_) => MaterialApp(
              theme: AppTheme.light,
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: NotificationTile(
                    notification: notification,
                    onTap: onTap,
                  ),
                ),
              ),
            ),
          ),
        ));

    Color? tintOf(WidgetTester tester) => tester
        .widget<Material>(find
            .descendant(
              of: find.byType(NotificationTile),
              matching: find.byType(Material),
            )
            .first)
        .color;

    testWidgets('an unread row is tinted and opens its target', (tester) async {
      var opened = 0;
      await pumpTile(
        tester,
        AppNotification(
          id: 'ntf-1',
          type: NotificationType.orderStatus,
          title: 'Your order has shipped',
          body: 'Order #ORD-2026-1258 is on its way.',
          createdAt: DateTime(2025, 12, 30, 17, 45),
        ),
        onTap: () => opened++,
      );

      expect(tintOf(tester), AppPalette.light.accent100);
      expect(find.text('notification_tag_order_status'), findsOneWidget);
      expect(find.text('Your order has shipped'), findsOneWidget);
      expect(find.text('Order #ORD-2026-1258 is on its way.'), findsOneWidget);
      expect(find.text('30/12/2025'), findsOneWidget);

      await tester.tap(find.byType(NotificationTile));
      expect(opened, 1);
    });

    testWidgets('a read row with nothing to say is not tinted', (tester) async {
      await pumpTile(
        tester,
        AppNotification(id: 'ntf-2', readAt: DateTime.utc(2026, 9, 1)),
      );

      expect(tintOf(tester), Colors.transparent);
      expect(find.byType(Text), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
