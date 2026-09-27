import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/paged.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/domain/entities/category.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_summary.dart';
import 'package:baytoti/features/catalog/domain/repositories/favourites_repository.dart';
import 'package:baytoti/features/catalog/domain/usecases/favourite_usecases.dart';
import 'package:baytoti/features/catalog/presentation/widgets/favourite_button.dart';
import 'package:baytoti/features/search/data/datasources/search_data_source.dart';
import 'package:baytoti/features/search/data/repositories/search_repository_impl.dart';
import 'package:baytoti/features/search/domain/entities/search_query.dart';
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
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

const String _products = 'cloak/products_page.json';
const String _categories = 'search/categories_active.json';

class _OfflineNetwork extends FakeNetwork {
  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async {
    calls.add(FakeCall('GET', url, queryParameters, null, headers));
    throw const ConnectionException();
  }
}

ProductSummary _product(String id, {bool favourite = false}) => ProductSummary(
      id: id,
      name: 'Product $id',
      family: const FamilyRef(id: '1', name: 'Family', city: 'Hawalli'),
      price: const Money(fils: 1000),
      isFavourite: favourite,
    );

Paged<ProductSummary> _results(
  List<String> ids, {
  int lastPage = 1,
  int? total,
}) =>
    Paged(
      items: [for (final id in ids) _product(id)],
      lastPage: lastPage,
      total: total ?? ids.length,
    );

const Category _desserts = Category(
  id: '5',
  slug: 'desserts',
  name: 'الحلويات',
  icon: CategoryIcon.sweets,
);

class _Call {
  final SearchQuery query;
  final Completer<Either<Failure, Paged<ProductSummary>>> completer =
      Completer();

  _Call(this.query);
}

class _FakeSearchRepository implements SearchRepository {
  final List<_Call> calls = [];
  Either<Failure, Paged<ProductSummary>>? autoAnswer;
  Either<Failure, List<Category>> categories = const Right([_desserts]);
  int categoryCalls = 0;

  @override
  Future<Either<Failure, Paged<ProductSummary>>> search(SearchQuery query) {
    final call = _Call(query);
    calls.add(call);
    final answer = autoAnswer;
    if (answer != null) call.completer.complete(answer);
    return call.completer.future;
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    categoryCalls++;
    return categories;
  }
}

class _FakeFavouritesRepository implements FavouritesRepository {
  final List<(String, bool)> calls = [];
  final Completer<Either<Failure, bool>> completer = Completer();

  @override
  Future<Either<Failure, List<ProductSummary>>> getFavourites() async =>
      const Right([]);

  @override
  Future<Either<Failure, bool>> setFavourite(String productId, bool favourite) {
    calls.add((productId, favourite));
    return completer.future;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('the query /products is sent', () {
    test('absent values are left out, the page size is not', () {
      expect(
        const SearchQuery().toQueryParameters(),
        {'sort': 'newest', 'per_page': 20},
      );
      expect(
        const SearchQuery().withText('   ').toQueryParameters(),
        isNot(contains('search')),
      );
      expect(const SearchQuery().withCategory('  ').categorySlug, isNull);

      final query = const SearchQuery()
          .withText(' كيك ')
          .withCategory('desserts')
          .withSort(SearchSort.priceAsc)
          .at(2);

      expect(query.toQueryParameters(), {
        'search': 'كيك',
        'category': 'desserts',
        'sort': 'price_asc',
        'page': 2,
        'per_page': 20,
      });
    });

    test('every sort offered is one the server accepts', () {
      const accepted = {
        'newest',
        'oldest',
        'price_asc',
        'price_desc',
        'name_asc',
        'name_desc',
      };

      expect(
        accepted,
        containsAll([for (final sort in SearchSort.values) sort.wire]),
      );
      expect(SearchSort.initial, SearchSort.newest);
    });

    test('clearing drops the category and a price order, not the words', () {
      final priced = const SearchQuery(text: 'كيك', sort: SearchSort.priceDesc)
          .withCategory('desserts');

      expect(priced.hasFilters, isTrue);
      expect(priced.cleared(), const SearchQuery(text: 'كيك'));
      expect(priced.cleared().hasFilters, isFalse);
    });
  });

  group('the remote search source', () {
    late FakeNetwork network;
    late SearchRepositoryImpl repository;

    setUp(() {
      network = FakeNetwork()
        ..replySample('GET', ApiEndPoint.products, _products)
        ..replySample('GET', ApiEndPoint.activeCategories, _categories);
      repository = SearchRepositoryImpl(SearchRemoteDataSource(network));
    });

    Future<Failure> searchFailure() async =>
        (await repository.search(const SearchQuery()))
            .fold((f) => f, (_) => throw StateError('accepted'));

    test('searches /products and reads the engine\'s page', () async {
      final page = (await repository.search(
        const SearchQuery().withText('عباية').withCategory('daily-abayas'),
      ))
          .getOrElse(() => throw StateError('refused'));

      expect(network.last('GET').url, ApiEndPoint.products);
      expect(network.last('GET').query, {
        'search': 'عباية',
        'category': 'daily-abayas',
        'sort': 'newest',
        'per_page': 20,
      });
      expect(page.total, 36);
      expect(page.hasMore, isTrue);
      expect(page.items.first.slug, 'aabay-mnasbat-fakhr-6');
      expect(page.items.first.price.fils, 55000);
      expect(page.items.first.family.name, 'مخمل');
      expect(page.items.first.family.city, isNull);
    });

    test('no match is an empty last page, not a failure', () async {
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'search/products_empty.cloak.json',
      );

      final page = (await repository.search(const SearchQuery()))
          .getOrElse(() => throw StateError('refused'));

      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });

    test('the categories to filter by come from /categories/active',
        () async {
      final categories = (await repository.getCategories())
          .getOrElse(() => throw StateError('refused'));

      expect(network.last('GET').url, ApiEndPoint.activeCategories);
      expect(categories, hasLength(10));
      expect(categories.first.id, '1');
      expect(categories.first.slug, 'home-cooked-food');
      expect(categories.first.name, 'الأكل البيتي');
      expect(categories.first.imageUrl, contains('photo-1547592180'));
      expect(categories[4].slug, 'desserts');
    });

    test('the /categories answer reads the same way', () async {
      network.replySample(
        'GET',
        ApiEndPoint.activeCategories,
        'betouti/categories.json',
      );

      final categories = (await repository.getCategories())
          .getOrElse(() => throw StateError('refused'));

      expect(
        categories.map((c) => c.slug),
        containsAllInOrder(['home-cooked-food', 'appetizers', 'main-dishes']),
      );
    });

    test('a rejected sort is a validation failure on its field', () async {
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'search/products_sort_422.json',
        status: 422,
      );

      final failure = await searchFailure();

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure)['sort'], 'sort غير موجود');
    });

    test('a 500 and a 401 are failures with their status', () async {
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/products_guest_500.json',
        status: 500,
      );
      final server = await searchFailure();

      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/unauthenticated_401.json',
        status: 401,
      );
      final refused = await searchFailure();

      expect(server, isA<ServerFailure>());
      expect(server.message, 'server_error');
      expect(refused.statusCode, 401);
    });

    test('offline is a network failure for both calls', () async {
      final offline = SearchRepositoryImpl(
        SearchRemoteDataSource(_OfflineNetwork()),
      );

      final search = (await offline.search(const SearchQuery()))
          .fold((f) => f, (_) => throw StateError('accepted'));
      final categories = (await offline.getCategories())
          .fold((f) => f, (_) => throw StateError('accepted'));

      expect(search, isA<NetworkFailure>());
      expect(categories, isA<NetworkFailure>());
    });
  });

  group('SearchCubit on the live shape', () {
    late FakeNetwork network;
    late SearchCubit cubit;

    setUp(() {
      network = FakeNetwork()
        ..replySample('GET', ApiEndPoint.products, _products)
        ..replySample('GET', ApiEndPoint.activeCategories, _categories);
      final repository = SearchRepositoryImpl(SearchRemoteDataSource(network));
      cubit = SearchCubit(
        SearchProductsUseCase(repository),
        GetSearchCategoriesUseCase(repository),
        SetFavouriteUseCase(_FakeFavouritesRepository()),
      );
    });

    tearDown(() => cubit.close());

    test('the route\'s words and category go out, then the categories',
        () async {
      await cubit.load(query: ' كيك ', categorySlug: 'desserts');

      expect(network.calls.map((c) => c.url), [
        ApiEndPoint.products,
        ApiEndPoint.activeCategories,
      ]);
      expect(network.calls.first.query, {
        'search': 'كيك',
        'category': 'desserts',
        'sort': 'newest',
        'per_page': 20,
      });
      expect(cubit.state.status, SearchStatus.loaded);
      expect(cubit.state.results!.total, 36);
      expect(cubit.state.categories, hasLength(10));
      expect(cubit.state.categoryName, 'الحلويات');
    });

    test('a failed search is an error screen and asks nothing more',
        () async {
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load();

      expect(cubit.state.status, SearchStatus.error);
      expect(cubit.state.results, isNull);
      expect(cubit.state.errorMessage, 'server_error');
      expect(network.calls, hasLength(1));
    });

    test('failed categories keep the results and say why', () async {
      network.replySample(
        'GET',
        ApiEndPoint.activeCategories,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load();

      expect(cubit.state.status, SearchStatus.loaded);
      expect(cubit.state.results!.items, hasLength(2));
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.errorMessage, 'server_error');
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
        GetSearchCategoriesUseCase(repository),
        SetFavouriteUseCase(favourites),
      );
    });

    tearDown(() => cubit.close());

    Future<void> loadWith(Paged<ProductSummary> results) async {
      final load = cubit.load();
      repository.calls.last.completer.complete(Right(results));
      await load;
    }

    test('a retry after an error searches again and loads categories',
        () async {
      final load = cubit.load(categorySlug: 'desserts');
      repository.calls.single.completer.complete(
        const Left(NetworkFailure(message: 'offline')),
      );
      await load;
      expect(cubit.state.status, SearchStatus.error);
      expect(repository.categoryCalls, 0);

      repository.autoAnswer = Right(_results(['a']));
      await cubit.retry();

      expect(repository.calls.last.query.categorySlug, 'desserts');
      expect(cubit.state.status, SearchStatus.loaded);
      expect(repository.categoryCalls, 1);
      expect(cubit.state.categoryName, 'الحلويات');
    });

    test('filters search at once and a repeat is not sent', () async {
      await loadWith(_results(['a']));
      repository.autoAnswer = Right(_results(['b']));

      await cubit.selectCategory('desserts');
      await cubit.selectCategory('desserts');
      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.query.categorySlug, 'desserts');

      await cubit.selectPriceSort(SearchSort.priceDesc);
      expect(cubit.state.query.sort, SearchSort.priceDesc);
      await cubit.selectPriceSort(null);
      expect(cubit.state.query.sort, SearchSort.newest);

      await cubit.setSort(SearchSort.priceAsc);
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

      cubit.selectCategory('desserts');
      cubit.selectCategory('breakfast');
      final older = repository.calls[1];
      final newer = repository.calls[2];

      newer.completer.complete(Right(_results(['breakfast'])));
      await _settle();
      older.completer.complete(Right(_results(['desserts'])));
      await _settle();

      expect(cubit.state.query.categorySlug, 'breakfast');
      expect(cubit.state.results!.items.single.id, 'breakfast');
    });

    test('the next page appends and stops at the last page', () async {
      await loadWith(_results(['a', 'b'], lastPage: 2, total: 3));

      final more = cubit.loadMore();
      cubit.loadMore();
      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.query.page, 2);
      expect(cubit.state.query.page, isNull);

      repository.calls.last.completer.complete(
        Right(Paged(items: [_product('c')], currentPage: 2, lastPage: 2)),
      );
      await more;

      expect(cubit.state.results!.items.map((p) => p.id), ['a', 'b', 'c']);
      expect(cubit.state.results!.total, 3);

      await cubit.loadMore();
      expect(repository.calls, hasLength(2));
    });

    test('a failed next page keeps the list', () async {
      await loadWith(_results(['a'], lastPage: 2));

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
      const price = Money(fils: 12500);
      final long = ProductSummary(
        id: 'long',
        name: 'A very long product name that has to wrap onto another line',
        family: const FamilyRef(
          id: '1',
          name: 'A family with a rather long name',
          city: 'Hawalli',
        ),
        price: price,
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
              query: const SearchQuery(categorySlug: 'desserts'),
              categoryName: 'الحلويات',
              onAll: () => taps.add('all'),
              onCategory: () => taps.add('category'),
              onPrice: () => taps.add('price'),
            ),
            SearchResultBar(
              total: 5,
              sort: SearchSort.newest,
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
      expect(find.text('الحلويات'), findsOneWidget);
      expect(
        find.text('A family with a rather long name · Hawalli'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'cake');
      await tester.tap(find.text('search_filter_all'));
      await tester.tap(find.text('الحلويات'));
      await tester.ensureVisible(find.text('search_filter_price'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('search_filter_price'));
      await tester.tap(find.text('search_sort_newest'));
      await tester.tap(find.text(price.display));
      await tester.tap(find.byType(FavouriteButton));

      expect(taps, [
        'typed cake',
        'all',
        'category',
        'price',
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
        SearchOption<String?>('desserts', 'Desserts', count: 2),
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
      await tester.tap(find.text('Desserts'));
      await tester.pumpAndSettle();
      expect((await picked)!.value, 'desserts');

      final cleared = showSearchOptionSheet<String?>(
        page,
        title: 'Category',
        options: options,
        selected: 'desserts',
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
