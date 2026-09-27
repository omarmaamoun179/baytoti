import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/paged.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_badge.dart';
import 'package:baytoti/features/catalog/domain/entities/product_summary.dart';
import 'package:baytoti/features/catalog/presentation/widgets/product_card.dart';
import 'package:baytoti/features/explore/data/datasources/explore_data_source.dart';
import 'package:baytoti/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:baytoti/features/explore/domain/entities/explore_tab.dart';
import 'package:baytoti/features/explore/domain/repositories/explore_repository.dart';
import 'package:baytoti/features/explore/domain/usecases/explore_usecases.dart';
import 'package:baytoti/features/explore/presentation/cubit/explore_cubit.dart';
import 'package:baytoti/features/explore/presentation/cubit/explore_state.dart';
import 'package:baytoti/features/explore/presentation/widgets/explore_tab_strip.dart';
import 'package:baytoti/features/explore/presentation/widgets/product_grid_sliver.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

const String _firstPage = 'cloak/products_page.json';
const String _lastPage = 'explore/products_last_page.cloak.json';

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

ProductSummary _product(String id) => ProductSummary(
      id: id,
      name: 'Product $id',
      family: const FamilyRef(id: '1', name: 'Family'),
      price: const Money(fils: 1000),
    );

Paged<ProductSummary> _page(List<String> ids, {int lastPage = 1}) => Paged(
      items: [for (final id in ids) _product(id)],
      lastPage: lastPage,
    );

class _Call {
  final ExploreTab tab;
  final int page;
  final Completer<Either<Failure, Paged<ProductSummary>>> completer =
      Completer();

  _Call(this.tab, this.page);
}

class _FakeExploreRepository implements ExploreRepository {
  final List<_Call> calls = [];

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    ExploreTab tab, {
    int page = 1,
  }) {
    final call = _Call(tab, page);
    calls.add(call);
    return call.completer.future;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeNetwork network;
  late ExploreRepositoryImpl repository;

  setUp(() {
    network = FakeNetwork()
      ..replySample('GET', ApiEndPoint.products, _firstPage);
    repository = ExploreRepositoryImpl(ExploreRemoteDataSource(network));
  });

  group('explore is GET /products', () {
    test('each tab asks for a sort or filter the engine accepts', () async {
      final sent = <ExploreTab, Map<String, dynamic>?>{};
      for (final tab in ExploreTab.values) {
        await repository.getProducts(tab);
        expect(network.last('GET').url, ApiEndPoint.products);
        sent[tab] = network.last('GET').query;
      }

      expect(sent, {
        ExploreTab.newest: {'sort': 'newest', 'page': 1, 'per_page': 20},
        ExploreTab.featured: {'featured': 1, 'page': 1, 'per_page': 20},
        ExploreTab.priceLow: {'sort': 'price_asc', 'page': 1, 'per_page': 20},
      });
      expect(ExploreTab.initial, ExploreTab.newest);
    });

    test('a later page carries its number', () async {
      await repository.getProducts(ExploreTab.priceLow, page: 3);

      expect(network.last('GET').query, {
        'sort': 'price_asc',
        'page': 3,
        'per_page': 20,
      });
    });

    test('the engine\'s product page parses with its paging', () async {
      final page = (await repository.getProducts(ExploreTab.newest))
          .getOrElse(() => throw StateError('refused'));
      final first = page.items.first;

      expect(page.items, hasLength(2));
      expect(page.currentPage, 1);
      expect(page.lastPage, 18);
      expect(page.total, 36);
      expect(page.hasMore, isTrue);
      expect(page.nextPage, 2);

      expect(first.id, '32');
      expect(first.slug, 'aabay-mnasbat-fakhr-6');
      expect(first.name, 'عباية مناسبات فاخرة 6');
      expect(first.price.fils, 55000);
      expect(first.compareAt?.fils, 65000);
      expect(first.family.slug, 'mkhml-6');
      expect(first.family.name, 'مخمل');
      expect(first.images.first.url, contains('photo-1551488831'));
      expect(first.badge, ProductBadge.featured);
    });

    test('the last page says there is no more', () async {
      network.replySample('GET', ApiEndPoint.products, _lastPage);

      final page = (await repository.getProducts(ExploreTab.newest, page: 18))
          .getOrElse(() => throw StateError('refused'));

      expect(page.currentPage, 18);
      expect(page.hasMore, isFalse);
      expect(page.items.map((p) => p.id), ['2', '1']);
    });

    test('a 500 and a 401 are failures with their status', () async {
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/products_guest_500.json',
        status: 500,
      );
      final server = (await repository.getProducts(ExploreTab.newest))
          .fold((f) => f, (_) => throw StateError('accepted'));

      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/unauthenticated_401.json',
        status: 401,
      );
      final refused = (await repository.getProducts(ExploreTab.newest))
          .fold((f) => f, (_) => throw StateError('accepted'));

      expect(server, isA<ServerFailure>());
      expect(server.statusCode, 500);
      expect(server.message, 'server_error');
      expect(refused.statusCode, 401);
    });

    test('offline is a network failure', () async {
      final offline = ExploreRepositoryImpl(
        ExploreRemoteDataSource(_OfflineNetwork()),
      );

      final failure = (await offline.getProducts(ExploreTab.newest))
          .fold((f) => f, (_) => throw StateError('accepted'));

      expect(failure, isA<NetworkFailure>());
    });
  });

  group('ExploreCubit on the live shape', () {
    late ExploreCubit cubit;

    setUp(() => cubit = ExploreCubit(GetExploreUseCase(repository)));
    tearDown(() => cubit.close());

    test('a first load lands as loaded with the newest products', () async {
      await cubit.load();

      expect(cubit.state.status, ExploreStatus.loaded);
      expect(cubit.state.tab, ExploreTab.newest);
      expect(cubit.state.productsTab, ExploreTab.newest);
      expect(cubit.state.products!.items, hasLength(2));
      expect(network.last('GET').query?['sort'], 'newest');
    });

    test('the next page appends, then paging stops at the last page',
        () async {
      await cubit.load();
      network.replySample('GET', ApiEndPoint.products, _lastPage);

      await cubit.loadMore();

      expect(network.last('GET').query?['page'], 2);
      expect(
        cubit.state.products!.items.map((p) => p.id),
        ['32', '22', '2', '1'],
      );
      expect(cubit.state.products!.hasMore, isFalse);

      await cubit.loadMore();
      expect(network.calls, hasLength(2));
    });

    test('a failed first load is an error screen', () async {
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load();

      expect(cubit.state.status, ExploreStatus.error);
      expect(cubit.state.errorMessage, 'server_error');
      expect(cubit.state.products, isNull);
    });

    test('a failed tab switch keeps the products and their tab', () async {
      await cubit.load();
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/products_guest_500.json',
        status: 500,
      );

      cubit.selectTab(ExploreTab.featured);
      expect(cubit.state.tab, ExploreTab.featured);
      expect(cubit.state.isSwitching, isTrue);
      await _settle();

      expect(network.last('GET').query?['featured'], 1);
      expect(cubit.state.status, ExploreStatus.loaded);
      expect(cubit.state.tab, ExploreTab.newest);
      expect(cubit.state.productsTab, ExploreTab.newest);
      expect(cubit.state.products!.items.first.id, '32');
      expect(cubit.state.errorMessage, 'server_error');
    });
  });

  group('ExploreCubit ordering', () {
    late _FakeExploreRepository fake;
    late ExploreCubit cubit;

    setUp(() {
      fake = _FakeExploreRepository();
      cubit = ExploreCubit(GetExploreUseCase(fake));
    });

    tearDown(() => cubit.close());

    test('an older tab answering late is dropped', () async {
      final first = cubit.load();
      fake.calls.first.completer.complete(Right(_page(['a'])));
      await first;

      cubit.selectTab(ExploreTab.featured);
      cubit.selectTab(ExploreTab.priceLow);
      final featured = fake.calls[1];
      final priceLow = fake.calls[2];

      priceLow.completer.complete(Right(_page(['cheap'])));
      await _settle();
      featured.completer.complete(Right(_page(['featured'])));
      await _settle();

      expect(cubit.state.tab, ExploreTab.priceLow);
      expect(cubit.state.productsTab, ExploreTab.priceLow);
      expect(cubit.state.products!.items.single.id, 'cheap');
    });

    test('tapping the selected tab does not reload', () async {
      final first = cubit.load();
      fake.calls.first.completer.complete(Right(_page(['a'])));
      await first;

      cubit.selectTab(ExploreTab.newest);

      expect(fake.calls, hasLength(1));
    });

    test('one next page is asked for at a time', () async {
      final first = cubit.load();
      fake.calls.first.completer.complete(Right(_page(['a'], lastPage: 2)));
      await first;

      final more = cubit.loadMore();
      cubit.loadMore();
      expect(fake.calls, hasLength(2));
      expect(fake.calls.last.page, 2);
      expect(fake.calls.last.tab, ExploreTab.newest);

      fake.calls.last.completer.complete(
        const Left(NetworkFailure(message: 'offline')),
      );
      await more;

      expect(cubit.state.status, ExploreStatus.loaded);
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.products!.items.single.id, 'a');
      expect(cubit.state.errorMessage, 'offline');
    });
  });

  group('explore widgets', () {
    testWidgets('the tabs and a product grid lay out at phone width',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final selected = <ExploreTab>[];
      final taps = <String>[];
      final long = ProductSummary(
        id: 'long',
        name: 'A very long product name that has to wrap onto another line',
        family: const FamilyRef(id: '1', name: 'A family with a long name'),
        price: const Money(fils: 12500),
      );

      await tester.pumpWidget(ScreenUtilScope(
        child: Builder(
          builder: (_) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ExploreTabStrip(
                      selected: ExploreTab.newest,
                      onSelect: selected.add,
                    ),
                  ),
                  ProductGridSliver(
                    products: [long, _product('b'), _product('c')],
                    onOpen: (product) => taps.add('open ${product.id}'),
                    onAdd: (product) => taps.add('add ${product.id}'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.byType(ProductCard), findsNWidgets(3));

      await tester.tap(find.text('explore_tab_featured'));
      await tester.tap(find.text('Product c'));
      await tester.tap(find.byType(AddButton).first);

      expect(selected, [ExploreTab.featured]);
      expect(taps, ['open c', 'add long']);
    });
  });
}
