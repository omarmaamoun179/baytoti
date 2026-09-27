import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/paged.dart';
import 'package:baytoti/core/theme/app_palette.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/notifications/data/datasources/notifications_data_source.dart';
import 'package:baytoti/features/notifications/data/models/notification_model.dart';
import 'package:baytoti/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:baytoti/features/notifications/domain/entities/app_notification.dart';
import 'package:baytoti/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:baytoti/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:baytoti/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:baytoti/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:baytoti/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Answer = Future<Either<Failure, NotificationFeed>> Function(
  NotificationsQuery query,
);

class _FakeRepository implements NotificationsRepository {
  _Answer answer;
  final List<NotificationsQuery> queries = [];
  int markCalls = 0;

  _FakeRepository(this.answer);

  @override
  Future<Either<Failure, NotificationFeed>> getNotifications(
    NotificationsQuery query,
  ) {
    queries.add(query);
    return answer(query);
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() async {
    markCalls++;
    return const Right(unit);
  }
}

AppNotification _notification(String id, {bool isRead = false}) =>
    AppNotification(
      id: id,
      type: NotificationType.offer,
      isRead: isRead,
      title: 'Title $id',
      body: 'Body $id',
      createdDisplay: 'now',
    );

Either<Failure, NotificationFeed> _feed(
  List<AppNotification> items, {
  String? nextCursor,
}) =>
    Right(NotificationFeed(
      page: Paged<AppNotification>(items: items, nextCursor: nextCursor),
      unreadCount: items.where((n) => !n.isRead).length,
    ));

const Failure _offline = NetworkFailure(message: 'You are offline.');

NotificationsCubit _cubit(_FakeRepository repository) => NotificationsCubit(
      GetNotificationsUseCase(repository),
      MarkNotificationsReadUseCase(repository),
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

T _right<T>(Either<Failure, T> result) =>
    result.fold((failure) => throw StateError('$failure'), (value) => value);

void main() {
  group('the notifications contract', () {
    test('the fixture feed parses in both languages', () {
      final backend = FixtureBackend();

      for (final lang in ['ar', 'en']) {
        final feed = NotificationFeedModel.fromJson(backend.notifications(lang));
        final items = feed.page.items;

        expect(items, hasLength(6));
        expect(feed.unreadCount, 3);
        expect(feed.page.hasMore, isFalse);
        expect(items.first.id, 'ntf_6');
        expect(items.first.type, NotificationType.orderStatus);
        expect(items.first.isRead, isFalse);
        expect(
          items.first.target,
          const NotificationTarget(
            kind: NotificationTargetKind.order,
            id: 'ord_2041',
          ),
        );
        expect(items[1].target?.kind, NotificationTargetKind.family);
        expect(items[2].target, isNull);
        expect(items.map((n) => n.type).toSet(), NotificationType.values.toSet());
        expect(items.every((n) => n.title.isNotEmpty), isTrue);
        expect(items.every((n) => n.createdDisplay.isNotEmpty), isTrue);
      }
    });

    test('an unknown type or target kind is read leniently', () {
      final feed = NotificationFeedModel.fromJson({
        'items': [
          {
            'id': 'ntf_99',
            'type': 'mystery',
            'is_read': false,
            'title': 'Hello',
            'body': 'World',
            'created_display': 'now',
            'target': {'kind': 'ticket', 'id': 't_1'},
          },
        ],
        'next_cursor': 'c_2',
      });

      final item = feed.page.items.single;
      expect(item.type, isNull);
      expect(item.target, isNull);
      expect(feed.unreadCount, 1);
      expect(feed.page.nextCursor, 'c_2');
      expect(feed.page.hasMore, isTrue);
    });

    test('each type has its own tag key', () {
      expect(
        NotificationType.values.map((type) => type.tagKey),
        [
          'notification_tag_order_status',
          'notification_tag_offer',
          'notification_tag_exhibition',
          'notification_tag_family_update',
          'notification_tag_rating_request',
          'notification_tag_support',
        ],
      );
    });

    test('the query omits an absent cursor', () {
      expect(const NotificationsQuery().toQueryParameters(), isEmpty);
      expect(
        const NotificationsQuery(cursor: 'c_2').toQueryParameters(),
        {'cursor': 'c_2'},
      );
    });
  });

  group('the fixture source through the repository', () {
    test('marking all read is what the next read reports', () async {
      final repository = NotificationsRepositoryImpl(
        NotificationsMockDataSource(FixtureBackend(), () async => 'en'),
      );

      final first = _right(
        await repository.getNotifications(const NotificationsQuery()),
      );
      expect(first.unreadCount, 3);
      expect(first.page.items.first.title, 'Order BT-2041 is being prepared');

      expect(await repository.markAllRead(), const Right<Failure, Unit>(unit));

      final second = _right(
        await repository.getNotifications(const NotificationsQuery()),
      );
      expect(second.unreadCount, 0);
      expect(second.page.items.every((n) => n.isRead), isTrue);
    });
  });

  group('NotificationsCubit', () {
    test('a first page loads, then everything is marked read', () async {
      final repository = _FakeRepository(
        (_) async => _feed([_notification('a'), _notification('b')]),
      );
      final cubit = _cubit(repository);
      final states = <NotificationsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await _settle();

      expect(states.map((s) => s.status), [
        NotificationsStatus.loading,
        NotificationsStatus.loaded,
      ]);
      expect(cubit.state.notifications.map((n) => n.id), ['a', 'b']);
      expect(cubit.state.notifications.first.isRead, isFalse);
      expect(repository.markCalls, 1);
      expect(repository.queries.single.cursor, isNull);

      await sub.cancel();
      await cubit.close();
    });

    test('nothing is marked read when nothing is unread', () async {
      final repository = _FakeRepository(
        (_) async => _feed([_notification('a', isRead: true)]),
      );
      final cubit = _cubit(repository);

      await cubit.load();
      await _settle();

      expect(repository.markCalls, 0);
      await cubit.close();
    });

    test('a failed first read is an error screen', () async {
      final repository = _FakeRepository((_) async => const Left(_offline));
      final cubit = _cubit(repository);

      await cubit.load();

      expect(cubit.state.status, NotificationsStatus.error);
      expect(cubit.state.errorMessage, 'You are offline.');
      expect(repository.markCalls, 0);
      await cubit.close();
    });

    test('a failed refresh keeps the list', () async {
      final repository = _FakeRepository(
        (_) async => _feed([_notification('a')]),
      );
      final cubit = _cubit(repository);
      await cubit.load();

      repository.answer = (_) async => const Left(_offline);
      await cubit.load();

      expect(cubit.state.status, NotificationsStatus.loaded);
      expect(cubit.state.notifications, hasLength(1));
      expect(cubit.state.errorMessage, 'You are offline.');
      await cubit.close();
    });

    test('two loads at once send one request', () async {
      final gate = Completer<Either<Failure, NotificationFeed>>();
      final repository = _FakeRepository((_) => gate.future);
      final cubit = _cubit(repository);

      final first = cubit.load();
      final second = cubit.load();
      gate.complete(_feed([_notification('a')]));
      await Future.wait([first, second]);

      expect(repository.queries, hasLength(1));
      expect(cubit.state.isLoaded, isTrue);
      await cubit.close();
    });

    test('the next page is read by cursor and appended', () async {
      final repository = _FakeRepository(
        (query) async => query.cursor == null
            ? _feed([_notification('a')], nextCursor: 'c_2')
            : _feed([_notification('b', isRead: true)]),
      );
      final cubit = _cubit(repository);
      await cubit.load();

      await cubit.loadMore();

      expect(repository.queries.last.cursor, 'c_2');
      expect(cubit.state.notifications.map((n) => n.id), ['a', 'b']);
      expect(cubit.state.page.hasMore, isFalse);
      expect(cubit.state.isLoadingMore, isFalse);

      await cubit.loadMore();
      expect(repository.queries, hasLength(2));
      await cubit.close();
    });

    test('a failed next page keeps the list', () async {
      final repository = _FakeRepository(
        (query) async => query.cursor == null
            ? _feed([_notification('a')], nextCursor: 'c_2')
            : const Left(_offline),
      );
      final cubit = _cubit(repository);
      await cubit.load();

      await cubit.loadMore();

      expect(cubit.state.status, NotificationsStatus.loaded);
      expect(cubit.state.notifications.map((n) => n.id), ['a']);
      expect(cubit.state.page.nextCursor, 'c_2');
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.errorMessage, 'You are offline.');
      await cubit.close();
    });

    test('a page that lands after a refresh is dropped', () async {
      final nextPage = Completer<Either<Failure, NotificationFeed>>();
      var refreshed = false;
      final repository = _FakeRepository((query) async {
        if (query.cursor != null) return nextPage.future;
        return refreshed
            ? _feed([_notification('fresh')], nextCursor: 'c_9')
            : _feed([_notification('a')], nextCursor: 'c_2');
      });
      final cubit = _cubit(repository);
      await cubit.load();

      final more = cubit.loadMore();
      refreshed = true;
      await cubit.load();
      nextPage.complete(_feed([_notification('stale')]));
      await more;

      expect(cubit.state.notifications.map((n) => n.id), ['fresh']);
      expect(cubit.state.page.nextCursor, 'c_9');
      expect(cubit.state.isLoadingMore, isFalse);
      await cubit.close();
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
        const AppNotification(
          id: 'ntf_6',
          type: NotificationType.orderStatus,
          isRead: false,
          title: 'Order BT-2041 is being prepared',
          body: 'Umm Abdullah Family started preparing your order.',
          createdDisplay: 'now',
        ),
        onTap: () => opened++,
      );

      expect(tintOf(tester), AppPalette.light.accent100);
      expect(find.text('notification_tag_order_status'), findsOneWidget);
      expect(find.text('now'), findsOneWidget);

      await tester.tap(find.byType(NotificationTile));
      expect(opened, 1);
    });

    testWidgets('a read row is not tinted', (tester) async {
      await pumpTile(tester, _notification('ntf_1', isRead: true));

      expect(tintOf(tester), Colors.transparent);
      expect(tester.takeException(), isNull);
    });
  });
}
