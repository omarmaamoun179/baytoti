import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/paged.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/constants.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/network_photo.dart';
import 'package:baytoti/core/widgets/stat_grid.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_summary.dart';
import 'package:baytoti/features/catalog/presentation/widgets/product_card.dart';
import 'package:baytoti/features/family/data/datasources/family_data_source.dart';
import 'package:baytoti/features/family/data/models/family_profile_model.dart';
import 'package:baytoti/features/family/data/repositories/family_repository_impl.dart';
import 'package:baytoti/features/family/domain/entities/family_profile.dart';
import 'package:baytoti/features/family/domain/repositories/family_repository.dart';
import 'package:baytoti/features/family/domain/usecases/family_usecases.dart';
import 'package:baytoti/features/family/presentation/cubit/family_cubit.dart';
import 'package:baytoti/features/family/presentation/cubit/family_state.dart';
import 'package:baytoti/features/family/presentation/widgets/family_header.dart';
import 'package:baytoti/features/family/presentation/widgets/family_product_row.dart';
import 'package:baytoti/features/family/presentation/widgets/family_stats.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cart_harness.dart';
import 'support/fake_network.dart';

const _slug = 'mkhml-6';

const _family = FamilyProfile(
  id: '1',
  slug: 'mtbkh-amyr-1',
  name: 'Amira Kitchen',
  story: 'Home-made Egyptian food, cooked every day.',
  city: 'Hawalli',
  isVerified: true,
);

Map<String, dynamic> _row(String sample, [int index = 0]) {
  final json = apiSample(sample)! as Map;
  final data = json['data'];
  return Map<String, dynamic>.from(data is List ? data[index] as Map : data as Map);
}

ProductSummary _summary(String id, [String name = 'Kubba']) => ProductSummary(
      id: id,
      name: name,
      family: const FamilyRef(id: '1', name: 'Amira Kitchen'),
      price: const Money(fils: 4500),
    );

Paged<ProductSummary> _page(List<String> ids, [int lastPage = 1]) => Paged(
      items: [for (final id in ids) _summary(id)],
      lastPage: lastPage,
    );

class _BrokenNetwork extends FakeNetwork {
  final AppException error;

  _BrokenNetwork(this.error);

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async =>
      throw error;
}

class _GatedFamilyRepository implements FamilyRepository {
  final Map<int?, Either<Failure, Paged<ProductSummary>>> pages = {
    null: Right(_page(['1', '2'], 2)),
    2: Right(_page(['3'])),
  };
  final Map<int?, Completer<void>> gates = {};
  final List<int?> pageRequests = [];

  @override
  Future<Either<Failure, FamilyProfile>> getFamily(String slug) async =>
      const Right(_family);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String slug, {
    int? page,
  }) async {
    pageRequests.add(page);
    await gates[page]?.future;
    return pages[page]!;
  }
}

FakeNetwork _backend() => FakeNetwork()
  ..replySample('GET', ApiEndPoint.store(_slug), 'cloak/store_detail.json')
  ..replySample('GET', ApiEndPoint.products, 'cloak/products_page.json');

FamilyCubit _cubit(FamilyRepository repository) => FamilyCubit(
      GetFamilyUseCase(repository),
      GetFamilyProductsUseCase(repository),
    );

Failure _failure<T>(Either<Failure, T> result) =>
    result.fold((failure) => failure, (value) => fail('expected a failure'));

T _value<T>(Either<Failure, T> result) =>
    result.getOrElse(() => fail('expected a value, got $result'));

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(withGuestCart(ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    )));

void main() {
  group('FamilyProfileModel reads the real shapes', () {
    test('the store detail reads its logo, banner and description', () {
      final family =
          FamilyProfileModel.fromJson(_row('cloak/store_detail.json'));

      expect(family.id, '6');
      expect(family.slug, _slug);
      expect(family.name, 'مخمل');
      expect(family.story, isNotEmpty);
      expect(family.avatar?.url, contains('photo-1556761175'));
      expect(family.cover?.url, contains('photo-1483985988355'));
      expect(family.isVerified, isFalse);
      expect(family.city, isNull);
      expect(family.productCount, isNull);
      expect(family.rating, isNull);
    });

    test('a Betouti store reads the _url keys and the trusted flag', () {
      final home = (apiSample('betouti/home.json')! as Map)['data'] as Map;
      final family = FamilyProfileModel.fromJson(
        Map<String, dynamic>.from((home['trusted_stores'] as List).first as Map),
      );

      expect(family.id, '1');
      expect(family.slug, 'mtbkh-amyr-1');
      expect(family.isVerified, isTrue);
      expect(family.avatar?.url, contains('photo-1556910103'));
      expect(family.cover?.url, contains('photo-1556911220'));
    });

    test('a bare store has no photos and no story', () {
      final family =
          FamilyProfileModel.fromJson(_row('cloak/stores_page.json'));

      expect(family.slug, 'test-2');
      expect(family.story, isEmpty);
      expect(family.avatar, isNull);
      expect(family.cover, isNull);
    });

    test('counts are read when the server sends them', () {
      final family = FamilyProfileModel.fromJson({
        ..._row('cloak/store_detail.json'),
        'products_count': 24,
        'average_rating': 4.9,
        'governorate': {'id': 3, 'name': 'حولي'},
      });

      expect(family.productCount, 24);
      expect(family.rating, 4.9);
      expect(family.city, 'حولي');
    });

    test('a store without an id is refused', () {
      expect(
        () => FamilyProfileModel.fromJson(const {'name': 'x'}),
        throwsFormatException,
      );
    });
  });

  group('FamilyRemoteDataSource', () {
    late FakeNetwork network;
    late FamilyRemoteDataSource source;

    setUp(() {
      network = _backend();
      source = FamilyRemoteDataSource(network);
    });

    test('a store is read by its slug', () async {
      final family = _value(await source.getFamily(_slug));

      expect(family.name, 'مخمل');
      expect(network.last('GET').url, ApiEndPoint.store(_slug));
    });

    test('its products are the catalogue filtered by the store slug',
        () async {
      final page = _value(await source.getProducts(_slug));

      expect(network.last('GET').url, ApiEndPoint.products);
      expect(
        network.last('GET').query,
        {'store': _slug, 'per_page': defaultPageSize},
      );
      expect(page.items.length, 2);
      expect(page.items.first.family.slug, _slug);
      expect(page.items.first.price.fils, 55000);
      expect(page.hasMore, isTrue);
      expect(page.total, 36);
    });

    test('a later page names its number', () async {
      await source.getProducts(_slug, page: 2);

      expect(
        network.last('GET').query,
        {'store': _slug, 'page': 2, 'per_page': defaultPageSize},
      );
    });

    test('an unknown store is a not-found failure', () async {
      network.replySample(
        'GET',
        ApiEndPoint.store('no-such-store'),
        'family/not_found_404.cloak_shape.json',
        status: 404,
      );

      final failure = _failure(await source.getFamily('no-such-store'));

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 404);
      expect(failure.message, 'family_not_found');
    });

    test('a server error and a signed-out answer are failures', () async {
      network
        ..replySample(
          'GET',
          ApiEndPoint.products,
          'betouti/products_guest_500.json',
          status: 500,
        )
        ..replySample(
          'GET',
          ApiEndPoint.store(_slug),
          'betouti/unauthenticated_401.json',
          status: 401,
        );

      final products = _failure(await source.getProducts(_slug));
      final family = _failure(await source.getFamily(_slug));

      expect(products.message, 'server_error');
      expect(products.statusCode, 500);
      expect(family.statusCode, 401);
    });

    test('a products answer without a list is a failure', () async {
      network.reply(
        'GET',
        ApiEndPoint.products,
        body: {'success': true, 'data': {'id': 1}},
      );

      final failure = _failure(await source.getProducts(_slug));

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'family_failed');
    });

    test('offline is a network failure', () async {
      final offline =
          FamilyRemoteDataSource(_BrokenNetwork(const ConnectionException()));

      expect(_failure(await offline.getFamily(_slug)), isA<NetworkFailure>());
      expect(_failure(await offline.getProducts(_slug)), isA<NetworkFailure>());
    });
  });

  group('FamilyCubit against the network', () {
    late FakeNetwork network;
    late FamilyCubit cubit;

    setUp(() {
      network = _backend();
      cubit = _cubit(FamilyRepositoryImpl(FamilyRemoteDataSource(network)));
    });

    tearDown(() => cubit.close());

    test('a load shows the store with its first page', () async {
      await cubit.load(_slug);

      expect(cubit.state.status, FamilyStatus.loaded);
      expect(cubit.state.family?.slug, _slug);
      expect(cubit.state.products.items.length, 2);
      expect(cubit.state.productCount, 36);
    });

    test('the next page is appended', () async {
      await cubit.load(_slug);
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'family/store_products_last_page.cloak_shape.json',
      );

      await cubit.loadMore();

      expect(network.last('GET').query?['page'], 2);
      expect(cubit.state.products.items.length, 3);
      expect(cubit.state.products.hasMore, isFalse);
      expect(cubit.state.isLoadingMore, isFalse);
    });

    test('an unknown store is an error', () async {
      network.replySample(
        'GET',
        ApiEndPoint.store(_slug),
        'family/not_found_404.cloak_shape.json',
        status: 404,
      );

      await cubit.load(_slug);

      expect(cubit.state.status, FamilyStatus.error);
      expect(cubit.state.errorMessage, 'family_not_found');
    });

    test('a failed first page is an error too', () async {
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load(_slug);

      expect(cubit.state.status, FamilyStatus.error);
      expect(cubit.state.errorMessage, 'server_error');
    });

    test('a failed next page keeps the list and reports', () async {
      await cubit.load(_slug);
      network.replySample(
        'GET',
        ApiEndPoint.products,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.loadMore();

      expect(cubit.state.status, FamilyStatus.loaded);
      expect(cubit.state.products.items.length, 2);
      expect(cubit.state.errorMessage, 'server_error');
      expect(cubit.state.isLoadingMore, isFalse);
    });
  });

  group('FamilyCubit paging', () {
    late _GatedFamilyRepository repository;
    late FamilyCubit cubit;

    setUp(() {
      repository = _GatedFamilyRepository();
      cubit = _cubit(repository);
    });

    tearDown(() => cubit.close());

    test('the next page is asked for once, however often it is wanted',
        () async {
      await cubit.load('mtbkh-amyr-1');
      repository.gates[2] = Completer();

      final first = cubit.loadMore();
      final second = cubit.loadMore();
      expect(cubit.state.isLoadingMore, isTrue);

      repository.gates[2]!.complete();
      await Future.wait([first, second]);

      expect(repository.pageRequests, [null, 2]);
      expect(cubit.state.products.items.map((p) => p.id), ['1', '2', '3']);

      await cubit.loadMore();
      expect(repository.pageRequests, [null, 2]);
    });

    test('a page from before a reload is dropped', () async {
      await cubit.load('mtbkh-amyr-1');
      repository.gates[2] = Completer();

      final stale = cubit.loadMore();
      await cubit.load('mtbkh-amyr-1');
      repository.gates[2]!.complete();
      await stale;

      expect(cubit.state.products.items.length, 2);
      expect(cubit.state.isLoadingMore, isFalse);
    });
  });

  group('family widgets', () {
    testWidgets('the header lays out with no follow button', (tester) async {
      await _pump(tester, const FamilyHeader(family: _family));

      expect(tester.takeException(), isNull);
      expect(find.text('Amira Kitchen'), findsOneWidget);
      expect(find.text('Hawalli · family_verified'), findsOneWidget);
      expect(find.text('family_follow'), findsNothing);

      final photos = find.byType(NetworkPhoto);
      final cover = tester.getRect(photos.first);
      final avatar = tester.getRect(photos.last);
      expect(cover.height, FamilyHeader.coverHeight);
      expect(avatar.top, lessThan(cover.bottom));
    });

    testWidgets('stats show only what is known', (tester) async {
      await _pump(tester, const FamilyStats(productCount: 36));

      expect(find.text('36'), findsOneWidget);
      expect(find.text('family_stat_rating'), findsNothing);

      await _pump(tester, const FamilyStats());
      expect(find.byType(StatGrid), findsNothing);

      expect(
        FamilyStats.itemsFor(productCount: 3, rating: 4.9).map((i) => i.value),
        ['3', '4.9'],
      );
    });

    testWidgets('a product row keeps two cards level without overflow',
        (tester) async {
      await _pump(
        tester,
        FamilyProductRow(
          products: [
            _summary('1', 'Fried kubba with pine nuts and tahini sauce'),
            _summary('2', 'Bread'),
          ],
          onOpen: (_) {},
          onAdd: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      final cards = find.byType(ProductCard);
      expect(cards, findsNWidgets(2));
      expect(
        tester.getSize(cards.first).height,
        tester.getSize(cards.last).height,
      );
    });
  });
}
