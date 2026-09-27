import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/paged.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_summary.dart';
import 'package:baytoti/features/catalog/domain/repositories/favourites_repository.dart';
import 'package:baytoti/features/catalog/domain/usecases/favourite_usecases.dart';
import 'package:baytoti/features/catalog/presentation/widgets/favourite_button.dart';
import 'package:baytoti/features/search/data/datasources/search_data_source.dart';
import 'package:baytoti/features/search/data/models/search_model.dart';
import 'package:baytoti/features/search/data/repositories/search_repository_impl.dart';
import 'package:baytoti/features/search/domain/entities/search_query.dart';
import 'package:baytoti/features/search/domain/entities/search_results.dart';
import 'package:baytoti/features/search/domain/repositories/search_repository.dart';
import 'package:baytoti/features/search/domain/usecases/search_usecases.dart';
import 'package:baytoti/features/search/presentation/cubit/search_cubit.dart';
import 'package:baytoti/features/search/presentation/cubit/search_state.dart';
import 'package:baytoti/features/search/presentation/widgets/search_field.dart';
import 'package:baytoti/features/search/presentation/widgets/search_filter_bar.dart';
import 'package:baytoti/features/search/presentation/widgets/search_option_sheet.dart';
import 'package:baytoti/features/search/presentation/widgets/search_result_bar.dart';
import 'package:baytoti/features/search/presentation/widgets/search_result_row.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProductSummary _product(String id, {bool favourite = false}) => ProductSummary(
      id: id,
      name: 'Product $id',
      family: const FamilyRef(id: 'fam_1', name: 'Family', city: 'Hawalli'),
      price: const Money(fils: 1000, display: '1.000 KWD'),
      isFavourite: favourite,
    );

SearchResults _results(List<String> ids, {String? cursor, int? total}) =>
    SearchResults(
      page: Paged(
        items: [for (final id in ids) _product(id)],
        nextCursor: cursor,
        total: total ?? ids.length,
      ),
      facets: const SearchFacets(
        categories: [
          SearchFacet(value: 'cat_sweets', label: 'Sweets', count: 2),
        ],
      ),
    );

class _Call {
  final SearchQuery query;
  final Completer<Either<Failure, SearchResults>> completer = Completer();

  _Call(this.query);
}

class _FakeSearchRepository implements SearchRepository {
  final List<_Call> calls = [];
  Either<Failure, SearchResults>? autoAnswer;

  @override
  Future<Either<Failure, SearchResults>> search(SearchQuery query) {
    final call = _Call(query);
    calls.add(call);
    final answer = autoAnswer;
    if (answer != null) call.completer.complete(answer);
    return call.completer.future;
  }
}

class _FakeFavouritesRepository implements FavouritesRepository {
  final List<(String, bool)> calls = [];
  final Completer<Either<Failure, bool>> completer = Completer();

  @override
  Future<Either<Failure, bool>> setFavourite(String productId, bool favourite) {
    calls.add((productId, favourite));
    return completer.future;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('the search contract', () {
    final backend = FixtureBackend();

    test('the fixture answer parses through the model', () {
      final results = SearchResultsModel.fromJson(backend.search(lang: 'en'));

      expect(results.total, 6);
      expect(results.items, hasLength(6));
      expect(results.hasMore, isFalse);
      expect(results.facets.categories, hasLength(6));
      expect(results.facets.categories.first.value, 'cat_sweets');
      expect(results.facets.categories.first.label, 'Sweets');
      expect(results.facets.categories.first.count, 2);
      expect(results.facets.cities.map((c) => c.value), contains('Hawalli'));
      expect(results.facets.priceRange!.minFils, 1250);
      expect(results.facets.priceRange!.maxFils, 9500);
      expect(results.facets.categoryName('cat_spices'), 'Spices');
      expect(results.facets.cityName('Jahra'), 'Jahra');
      expect(results.items.first.family.city, isNotNull);
    });

    test('the query omits every absent value', () {
      expect(const SearchQuery().toQueryParameters(), {'sort': 'top_rated'});
      expect(
        const SearchQuery().withText('   ').toQueryParameters(),
        isNot(contains('q')),
      );

      final query = const SearchQuery()
          .withText(' cake ')
          .withCategory('cat_sweets')
          .withCity('Hawalli')
          .withMinRating(SearchQuery.highRating)
          .withSort(SearchSort.priceAsc)
          .at('c2');

      expect(query.toQueryParameters(), {
        'q': 'cake',
        'category_id': 'cat_sweets',
        'city': 'Hawalli',
        'min_rating': 4.5,
        'sort': 'price_asc',
        'cursor': 'c2',
      });
    });

    test('clearing drops the filters and a price order, not the words', () {
      final priced = const SearchQuery(text: 'cake', sort: SearchSort.priceDesc)
          .withCategory('cat_sweets')
          .withMinRating(4.5);

      expect(priced.hasFilters, isTrue);
      expect(priced.cleared(), const SearchQuery(text: 'cake'));
      expect(priced.cleared().hasFilters, isFalse);

      const newest = SearchQuery(sort: SearchSort.newest, city: 'Jahra');
      expect(newest.cleared().sort, SearchSort.newest);
    });

    test('the mock source filters and sorts through the repository', () async {
      final repository = SearchRepositoryImpl(
        SearchMockDataSource(FixtureBackend(), () async => 'ar'),
      );

      final sweets = (await repository.search(
        const SearchQuery(categoryId: 'cat_sweets'),
      ))
          .getOrElse(() => throw StateError('failed'));
      expect(sweets.total, 2);
      expect(sweets.items.map((p) => p.id), containsAll(['prd_1', 'prd_2']));

      final cheapest = (await repository.search(
        const SearchQuery(sort: SearchSort.priceAsc),
      ))
          .getOrElse(() => throw StateError('failed'));
      final prices = [for (final p in cheapest.items) p.price.fils];
      expect(prices, [...prices]..sort());

      final hawalli = (await repository.search(
        const SearchQuery(city: 'حولي'),
      ))
          .getOrElse(() => throw StateError('failed'));
      expect(hawalli.items.map((p) => p.family.city).toSet(), {'حولي'});
    });
  });

  group('SearchCubit', () {
    late _FakeSearchRepository repository;
    late _FakeFavouritesRepository favourites;
    late SearchCubit cubit;

    setUp(() {
      repository = _FakeSearchRepository();
      favourites = _FakeFavouritesRepository();
      cubit = SearchCubit(
        SearchProductsUseCase(repository),
        SetFavouriteUseCase(favourites),
      );
    });

    tearDown(() => cubit.close());

    Future<void> loadWith(SearchResults results) async {
      final load = cubit.load();
      repository.calls.last.completer.complete(Right(results));
      await load;
    }

    test('the first search carries the route values', () async {
      final load = cubit.load(query: ' cake ', categoryId: 'cat_sweets');
      expect(cubit.state.status, SearchStatus.loading);
      expect(repository.calls.single.query.text, 'cake');
      expect(repository.calls.single.query.categoryId, 'cat_sweets');
      expect(repository.calls.single.query.sort, SearchSort.topRated);

      repository.calls.single.completer.complete(Right(_results(['a'])));
      await load;

      expect(cubit.state.status, SearchStatus.loaded);
      expect(cubit.state.results!.total, 1);
    });

    test('a failed search is an error screen without results', () async {
      final load = cubit.load();
      repository.calls.single.completer.complete(
        const Left(ServerFailure(message: 'search_failed')),
      );
      await load;

      expect(cubit.state.status, SearchStatus.error);
      expect(cubit.state.results, isNull);
      expect(cubit.state.errorMessage, 'search_failed');
    });

    test('filters search at once and a repeat is not sent', () async {
      await loadWith(_results(['a']));
      repository.autoAnswer = Right(_results(['b']));

      await cubit.selectCategory('cat_sweets');
      await cubit.selectCategory('cat_sweets');
      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.query.categoryId, 'cat_sweets');

      await cubit.toggleRating();
      expect(repository.calls.last.query.minRating, 4.5);
      await cubit.toggleRating();
      expect(repository.calls.last.query.minRating, isNull);

      await cubit.selectPriceSort(SearchSort.priceDesc);
      expect(cubit.state.query.sort, SearchSort.priceDesc);
      await cubit.selectPriceSort(null);
      expect(cubit.state.query.sort, SearchSort.topRated);

      await cubit.selectCity('Hawalli');
      await cubit.clearFilters();
      expect(cubit.state.query, const SearchQuery());
      expect(cubit.state.query.hasFilters, isFalse);
    });

    test('typing is debounced into one search', () async {
      await loadWith(_results(['a']));
      repository.autoAnswer = Right(_results(['cake']));

      cubit.queryChanged('c');
      cubit.queryChanged('ca');
      cubit.queryChanged('cake ');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(repository.calls, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.query.text, 'cake');
      expect(cubit.state.results!.items.single.id, 'cake');
    });

    test('a submitted word is not searched again by the debounce', () async {
      await loadWith(_results(['a']));
      repository.autoAnswer = Right(_results(['cake']));

      cubit.queryChanged('cake');
      await cubit.submit('cake');
      await Future<void>.delayed(const Duration(milliseconds: 650));

      expect(repository.calls, hasLength(2));
    });

    test('an older search answering late is dropped', () async {
      await loadWith(_results(['a']));

      cubit.selectCategory('cat_sweets');
      cubit.selectCategory('cat_spices');
      final older = repository.calls[1];
      final newer = repository.calls[2];

      newer.completer.complete(Right(_results(['spices'])));
      await _settle();
      older.completer.complete(Right(_results(['sweets'])));
      await _settle();

      expect(cubit.state.query.categoryId, 'cat_spices');
      expect(cubit.state.results!.items.single.id, 'spices');
    });

    test('the next page appends and stops at the last cursor', () async {
      await loadWith(_results(['a', 'b'], cursor: 'c2', total: 3));

      final more = cubit.loadMore();
      cubit.loadMore();
      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.query.cursor, 'c2');
      expect(cubit.state.query.cursor, isNull);

      repository.calls.last.completer.complete(Right(_results(['c'])));
      await more;

      expect(cubit.state.results!.items.map((p) => p.id), ['a', 'b', 'c']);
      expect(cubit.state.results!.facets.categories, isNotEmpty);

      await cubit.loadMore();
      expect(repository.calls, hasLength(2));
    });

    test('a failed next page keeps the list', () async {
      await loadWith(_results(['a'], cursor: 'c2'));

      final more = cubit.loadMore();
      repository.calls.last.completer.complete(
        const Left(NetworkFailure(message: 'offline')),
      );
      await more;

      expect(cubit.state.status, SearchStatus.loaded);
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.results!.items.single.id, 'a');
      expect(cubit.state.errorMessage, 'offline');
    });

    test('a favourite shows at once and stays when saved', () async {
      await loadWith(_results(['a']));

      final toggle = cubit.toggleFavourite(cubit.state.results!.items.single);
      expect(cubit.state.results!.items.single.isFavourite, isTrue);
      expect(favourites.calls.single, ('a', true));

      favourites.completer.complete(const Right(true));
      await toggle;

      expect(cubit.state.results!.items.single.isFavourite, isTrue);
      expect(cubit.state.errorMessage, isNull);
    });

    test('a refused favourite rolls back with a message', () async {
      await loadWith(_results(['a']));

      final toggle = cubit.toggleFavourite(cubit.state.results!.items.single);
      cubit.toggleFavourite(cubit.state.results!.items.single);
      expect(favourites.calls, hasLength(1));

      favourites.completer.complete(
        const Left(ServerFailure(message: 'favourite_failed')),
      );
      await toggle;

      expect(cubit.state.results!.items.single.isFavourite, isFalse);
      expect(cubit.state.errorMessage, 'favourite_failed');
    });
  });

  group('search widgets', () {
    Future<BuildContext> pump(WidgetTester tester, Widget body) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late BuildContext page;

      await tester.pumpWidget(ScreenUtilScope(
        child: Builder(
          builder: (_) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Builder(builder: (context) {
                page = context;
                return body;
              }),
            ),
          ),
        ),
      ));
      return page;
    }

    testWidgets('the field, filters, bar and a row lay out at phone width',
        (tester) async {
      final taps = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final long = ProductSummary(
        id: 'long',
        name: 'A very long product name that has to wrap onto another line',
        family: const FamilyRef(
          id: 'fam_1',
          name: 'A family with a rather long name',
          city: 'Hawalli',
        ),
        price: const Money(fils: 12500, display: '12.500 KWD'),
      );

      await pump(
        tester,
        ListView(
          children: [
            SearchField(
              controller: controller,
              onChanged: (text) => taps.add('typed $text'),
              onSubmitted: (_) {},
            ),
            SearchFilterBar(
              query: const SearchQuery(categoryId: 'cat_sweets'),
              facets: const SearchFacets(
                categories: [
                  SearchFacet(value: 'cat_sweets', label: 'Sweets', count: 2),
                ],
              ),
              onAll: () => taps.add('all'),
              onCategory: () => taps.add('category'),
              onPrice: () => taps.add('price'),
              onCity: () => taps.add('city'),
              onRating: () => taps.add('rating'),
            ),
            SearchResultBar(
              total: 5,
              sort: SearchSort.topRated,
              onSort: () => taps.add('sort'),
            ),
            SearchResultRow(
              product: long,
              onOpen: () => taps.add('open'),
              onFavourite: () => taps.add('favourite'),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Sweets'), findsOneWidget);
      expect(
        find.text('A family with a rather long name · Hawalli'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'cake');
      await tester.tap(find.text('Sweets'));
      await tester.ensureVisible(find.text('search_filter_rating'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('search_filter_rating'));
      await tester.tap(find.text('search_sort_top_rated'));
      await tester.tap(find.text('12.500 KWD'));
      await tester.tap(find.byType(FavouriteButton));

      expect(taps, [
        'typed cake',
        'category',
        'rating',
        'sort',
        'open',
        'favourite',
      ]);
    });

    testWidgets('an option sheet hands back the pick, or nothing',
        (tester) async {
      final page = await pump(tester, const SizedBox.expand());
      const options = [
        SearchOption<String?>(null, 'All'),
        SearchOption<String?>('cat_sweets', 'Sweets', count: 2),
      ];

      final picked = showSearchOptionSheet<String?>(
        page,
        title: 'Category',
        options: options,
        selected: null,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('Sweets'));
      await tester.pumpAndSettle();
      expect((await picked)!.value, 'cat_sweets');

      final cleared = showSearchOptionSheet<String?>(
        page,
        title: 'Category',
        options: options,
        selected: 'cat_sweets',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      final pick = await cleared;
      expect(pick, isNotNull);
      expect(pick!.value, isNull);

      final dismissed = showSearchOptionSheet<String?>(
        page,
        title: 'Category',
        options: options,
        selected: null,
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(180, 20));
      await tester.pumpAndSettle();
      expect(await dismissed, isNull);
    });
  });
}
