import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_badge.dart';
import 'package:baytoti/features/catalog/domain/entities/product_summary.dart';
import 'package:baytoti/features/explore/data/datasources/explore_data_source.dart';
import 'package:baytoti/features/explore/data/models/explore_model.dart';
import 'package:baytoti/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:baytoti/features/explore/domain/entities/explore_feed.dart';
import 'package:baytoti/features/explore/domain/repositories/explore_repository.dart';
import 'package:baytoti/features/explore/domain/usecases/explore_usecases.dart';
import 'package:baytoti/features/explore/presentation/cubit/explore_cubit.dart';
import 'package:baytoti/features/explore/presentation/cubit/explore_state.dart';
import 'package:baytoti/features/explore/presentation/widgets/explore_tab_strip.dart';
import 'package:baytoti/features/explore/presentation/widgets/most_viewed_tile.dart';
import 'package:baytoti/features/explore/presentation/widgets/rising_row.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProductSummary _product(String id) => ProductSummary(
      id: id,
      name: 'Product $id',
      family: const FamilyRef(id: 'fam_1', name: 'Family'),
      price: const Money(fils: 1000, display: '1.000 KWD'),
    );

ExploreFeed _feed(List<String> ids, {int lastPage = 1}) => ExploreFeed(
      hashtags: const ['#tag'],
      rising: [
        RisingProduct(rank: 1, product: _product(ids.first), growth: '+10%'),
      ],
      mostViewed: [for (final id in ids) _product(id)],
      lastPage: lastPage,
    );

class _Call {
  final ExploreTab tab;
  final int? page;
  final Completer<Either<Failure, ExploreFeed>> completer = Completer();

  _Call(this.tab, this.page);
}

class _FakeExploreRepository implements ExploreRepository {
  final List<_Call> calls = [];

  @override
  Future<Either<Failure, ExploreFeed>> getExplore(
    ExploreTab tab, {
    int? page,
  }) {
    final call = _Call(tab, page);
    calls.add(call);
    return call.completer.future;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('the explore contract', () {
    final backend = FixtureBackend();

    test('the fixture feed parses through the model', () {
      final feed = ExploreFeedModel.fromJson(backend.explore('daily', 'en'));

      expect(feed.hashtags, hasLength(6));
      expect(feed.hashtags.first, '#kuwaitisweets');
      expect(feed.rising, hasLength(4));
      expect([for (final r in feed.rising) r.rank], [1, 2, 3, 4]);
      expect(feed.rising.first.product.id, 'prd_1');
      expect(feed.rising.first.product.badge, ProductBadge.bestSeller);
      expect(feed.rising.first.growth, '+38%');
      expect(feed.rising.first.product.price.fils, 4250);
      expect(feed.mostViewed, hasLength(9));
      expect(feed.currentPage, 1);
      expect(feed.hasMore, isFalse);
    });

    test('every tab answers in the same shape', () {
      for (final tab in ExploreTab.values) {
        final feed = ExploreFeedModel.fromJson(
          backend.explore(tab.wire, 'ar'),
        );

        expect(feed.rising, isNotEmpty, reason: tab.wire);
        expect(feed.mostViewed, isNotEmpty, reason: tab.wire);
      }
    });

    test('the new tab ranks only new products', () {
      final feed = ExploreFeedModel.fromJson(backend.explore('new', 'en'));

      expect(
        feed.rising.map((r) => r.product.badge).toSet(),
        {ProductBadge.newArrival},
      );
    });

    test('the mock source answers through the repository', () async {
      final repository = ExploreRepositoryImpl(
        ExploreMockDataSource(FixtureBackend(), () async => 'ar'),
      );

      final result = await repository.getExplore(ExploreTab.weekly);
      final feed = result.getOrElse(() => throw StateError('failed'));

      expect(feed.rising.first.product.id, 'prd_5');
      expect(feed.rising.first.product.name, 'خبز التنور الطازج');
      expect(feed.hashtags.first, '#حلويات_كويتية');
    });
  });

  group('presentation helpers', () {
    test('ranks print Arabic-Indic digits in Arabic', () {
      expect(rankLabel(1, 'ar'), '١');
      expect(rankLabel(4, 'ar'), '٤');
      expect(rankLabel(12, 'ar'), '١٢');
      expect(rankLabel(3, 'en'), '3');
    });

    test('a most-viewed tile shows the first word of the name', () {
      expect(MostViewedTile.labelOf('Cardamom date cake'), 'Cardamom');
      expect(MostViewedTile.labelOf('  كيك التمر بالهيل'), 'كيك');
    });
  });

  group('ExploreCubit', () {
    late _FakeExploreRepository repository;
    late ExploreCubit cubit;

    setUp(() {
      repository = _FakeExploreRepository();
      cubit = ExploreCubit(GetExploreUseCase(repository));
    });

    tearDown(() => cubit.close());

    test('a first load lands as loaded with the daily feed', () async {
      final load = cubit.load();
      expect(cubit.state.status, ExploreStatus.loading);
      expect(repository.calls.single.tab, ExploreTab.daily);

      repository.calls.single.completer.complete(Right(_feed(['a', 'b'])));
      await load;

      expect(cubit.state.status, ExploreStatus.loaded);
      expect(cubit.state.feedTab, ExploreTab.daily);
      expect(cubit.state.feed!.mostViewed, hasLength(2));
    });

    test('a failed first load is an error screen', () async {
      final load = cubit.load();
      repository.calls.single.completer.complete(
        const Left(NetworkFailure(message: 'offline')),
      );
      await load;

      expect(cubit.state.status, ExploreStatus.error);
      expect(cubit.state.errorMessage, 'offline');
      expect(cubit.state.feed, isNull);
    });

    test('a failed tab switch keeps the feed and its tab', () async {
      final first = cubit.load();
      repository.calls.first.completer.complete(Right(_feed(['a'])));
      await first;

      cubit.selectTab(ExploreTab.weekly);
      expect(cubit.state.tab, ExploreTab.weekly);
      expect(cubit.state.isSwitching, isTrue);

      repository.calls.last.completer.complete(
        const Left(ServerFailure(message: 'explore_failed')),
      );
      await _settle();

      expect(cubit.state.status, ExploreStatus.loaded);
      expect(cubit.state.tab, ExploreTab.daily);
      expect(cubit.state.feedTab, ExploreTab.daily);
      expect(cubit.state.feed!.mostViewed.single.id, 'a');
      expect(cubit.state.errorMessage, 'explore_failed');
    });

    test('an older tab answering late is dropped', () async {
      final first = cubit.load();
      repository.calls.first.completer.complete(Right(_feed(['a'])));
      await first;

      cubit.selectTab(ExploreTab.weekly);
      cubit.selectTab(ExploreTab.fresh);
      final weekly = repository.calls[1];
      final fresh = repository.calls[2];

      fresh.completer.complete(Right(_feed(['new'])));
      await _settle();
      weekly.completer.complete(Right(_feed(['weekly'])));
      await _settle();

      expect(cubit.state.tab, ExploreTab.fresh);
      expect(cubit.state.feedTab, ExploreTab.fresh);
      expect(cubit.state.feed!.mostViewed.single.id, 'new');
    });

    test('tapping the selected tab does not reload', () async {
      final first = cubit.load();
      repository.calls.first.completer.complete(Right(_feed(['a'])));
      await first;

      cubit.selectTab(ExploreTab.daily);

      expect(repository.calls, hasLength(1));
    });

    test('the next page appends to most viewed', () async {
      final first = cubit.load();
      repository.calls.first.completer.complete(
        Right(_feed(['a', 'b'], lastPage: 2)),
      );
      await first;

      final more = cubit.loadMore();
      cubit.loadMore();
      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.page, 2);

      repository.calls.last.completer.complete(Right(_feed(['c'])));
      await more;

      expect(
        cubit.state.feed!.mostViewed.map((p) => p.id),
        ['a', 'b', 'c'],
      );
      expect(cubit.state.feed!.hasMore, isFalse);

      await cubit.loadMore();
      expect(repository.calls, hasLength(2));
    });

    test('a failed next page keeps the feed', () async {
      final first = cubit.load();
      repository.calls.first.completer.complete(
        Right(_feed(['a'], lastPage: 2)),
      );
      await first;

      final more = cubit.loadMore();
      repository.calls.last.completer.complete(
        const Left(NetworkFailure(message: 'offline')),
      );
      await more;

      expect(cubit.state.status, ExploreStatus.loaded);
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.feed!.mostViewed.single.id, 'a');
      expect(cubit.state.errorMessage, 'offline');
    });
  });

  group('explore widgets', () {
    Future<void> pump(WidgetTester tester, List<Widget> slivers) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ScreenUtilScope(
        child: Builder(
          builder: (_) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: CustomScrollView(slivers: slivers)),
          ),
        ),
      ));
    }

    testWidgets('tabs, a rising row and the grid lay out at phone width',
        (tester) async {
      final selected = <ExploreTab>[];
      final opened = <String>[];
      final long = ProductSummary(
        id: 'long',
        name: 'A very long product name that has to wrap onto another line',
        family: const FamilyRef(id: 'fam_1', name: 'A family with a long name'),
        price: const Money(fils: 12500, display: '12.500 KWD'),
      );

      await pump(tester, [
        SliverToBoxAdapter(
          child: ExploreTabStrip(
            selected: ExploreTab.daily,
            onSelect: selected.add,
          ),
        ),
        SliverToBoxAdapter(
          child: RisingRow(
            item: RisingProduct(rank: 1, product: long, growth: '+38%'),
            languageCode: 'ar',
            onTap: () => opened.add('rising'),
          ),
        ),
        SliverGrid.count(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            for (final id in ['a', 'b', 'c', 'd'])
              MostViewedTile(
                product: _product(id),
                onTap: () => opened.add(id),
              ),
          ],
        ),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text('١'), findsOneWidget);
      expect(find.text('+38%'), findsOneWidget);

      await tester.tap(find.text('explore_tab_weekly'));
      await tester.tap(find.text('+38%'));
      await tester.tap(find.byType(MostViewedTile).at(2));

      expect(selected, [ExploreTab.weekly]);
      expect(opened, ['rising', 'c']);
    });
  });
}
