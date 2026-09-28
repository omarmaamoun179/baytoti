import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/home/data/datasources/home_data_source.dart';
import 'package:baytoti/features/home/data/repositories/home_repository_impl.dart';
import 'package:baytoti/features/home/domain/entities/home_feed.dart';
import 'package:baytoti/features/home/domain/usecases/get_stores_use_case.dart';
import 'package:baytoti/features/home/presentation/cubit/stores_cubit.dart';
import 'package:baytoti/features/home/presentation/widgets/home_section.dart';
import 'package:baytoti/features/home/presentation/widgets/trusted_store_card.dart';
import 'package:baytoti/features/home/presentation/widgets/trusted_store_rail.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

FakeNetwork _backend() => FakeNetwork()
  ..replySample('GET', ApiEndPoint.stores, 'betouti/stores.json');

HomeRemoteDataSource _source(FakeNetwork network) =>
    HomeRemoteDataSource(network);

StoresCubit _cubit(FakeNetwork network) => StoresCubit(
      GetStoresUseCase(HomeRepositoryImpl(_source(network))),
    );

Failure _failure<T>(Either<Failure, T> result) =>
    result.fold((failure) => failure, (value) => fail('expected a failure'));

List<TrustedStore> _value(Either<Failure, List<TrustedStore>> result) =>
    result.getOrElse(() => fail('expected stores, got $result'));

const _stores = [
  TrustedStore(
    family: FamilyRef(id: '1', slug: 'fam-1', name: 'مطبخ أميرة'),
    description: 'أكلات بيتية',
  ),
  TrustedStore(
    family: FamilyRef(id: '2', slug: 'fam-2', name: 'أكل زمان'),
    description: 'وصفات مصرية',
  ),
];

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: ListView(children: [child])),
        ),
      ),
    ));

void main() {
  group('GET /stores as Betouti answers it', () {
    test('asks the one endpoint with no query and reads every store',
        () async {
      final network = _backend();

      final stores = _value(await _source(network).getStores());

      expect(network.calls.length, 1);
      expect(network.last('GET').url, ApiEndPoint.stores);
      expect(network.last('GET').query, isNull);
      expect(stores.map((s) => s.family.slug), [
        'akl-zman-4',
        'hloyat-albyt-6',
        'mtbkh-amyr-1',
      ]);
    });

    test('a store reads the bare logo and banner keys and its description',
        () async {
      final store = _value(await _source(_backend()).getStores()).first;

      expect(store.family.id, '4');
      expect(store.family.name, 'أكل زمان');
      expect(store.description, 'وصفات مصرية أصيلة بطعم زمان.');
      expect(store.family.images.first.url, contains('photo-1556910103'));
      expect(store.bannerUrl, contains('photo-1556911220'));
      expect(store.family.isVerified, isFalse);
    });

    test('no stores is an empty list, not a failure', () async {
      final network = FakeNetwork()
        ..reply('GET', ApiEndPoint.stores, body: {'success': true, 'data': []});

      expect(_value(await _source(network).getStores()), isEmpty);
    });

    test('an answer without a list is a failure', () async {
      final network = FakeNetwork()
        ..reply(
          'GET',
          ApiEndPoint.stores,
          body: {'success': true, 'data': {'id': 1}},
        );

      final failure = _failure(await _source(network).getStores());

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'stores_failed');
    });

    test('a signed-out answer and a server error are failures', () async {
      final signedOut = FakeNetwork()
        ..replySample(
          'GET',
          ApiEndPoint.stores,
          'betouti/unauthenticated_401.json',
          status: 401,
        );
      final broken = FakeNetwork()
        ..replySample(
          'GET',
          ApiEndPoint.stores,
          'betouti/products_guest_500.json',
          status: 500,
        );

      expect(_failure(await _source(signedOut).getStores()).statusCode, 401);
      final server = _failure(await _source(broken).getStores());
      expect(server.statusCode, 500);
      expect(server.message, 'server_error');
    });

    test('offline is a network failure', () async {
      final failure = _failure(await _source(_OfflineNetwork()).getStores());

      expect(failure, isA<NetworkFailure>());
    });
  });

  group('StoresCubit', () {
    late FakeNetwork network;
    late StoresCubit cubit;

    setUp(() {
      network = _backend();
      cubit = _cubit(network);
    });

    tearDown(() => cubit.close());

    test('a load shows every store', () async {
      await cubit.load();

      expect(cubit.state.status, StoresStatus.loaded);
      expect(cubit.state.stores.length, 3);
      expect(cubit.state.errorMessage, isNull);
    });

    test('wanting the list twice at once asks once', () async {
      await Future.wait([cubit.load(), cubit.load()]);

      expect(network.calls.length, 1);
    });

    test('a failed first load is an error, and a retry recovers', () async {
      network.replySample(
        'GET',
        ApiEndPoint.stores,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load();

      expect(cubit.state.status, StoresStatus.error);
      expect(cubit.state.errorMessage, 'server_error');
      expect(cubit.state.stores, isEmpty);

      network.replySample('GET', ApiEndPoint.stores, 'betouti/stores.json');
      await cubit.load();

      expect(cubit.state.status, StoresStatus.loaded);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.stores.length, 3);
    });

    test('a failed refresh keeps the list and reports', () async {
      await cubit.load();
      network.replySample(
        'GET',
        ApiEndPoint.stores,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load();

      expect(cubit.state.status, StoresStatus.loaded);
      expect(cubit.state.stores.length, 3);
      expect(cubit.state.errorMessage, 'server_error');
    });

    test('a refresh replaces the list', () async {
      await cubit.load();
      network.reply('GET', ApiEndPoint.stores, body: {'success': true, 'data': []});

      await cubit.load();

      expect(cubit.state.status, StoresStatus.loaded);
      expect(cubit.state.stores, isEmpty);
    });
  });

  group('the trusted stores row', () {
    testWidgets('Show all sits beside the title and opens the list',
        (tester) async {
      var showAll = 0;
      final opened = <String>[];

      await _pump(
        tester,
        HomeSection(
          title: 'home_trusted_stores',
          actionLabel: 'home_show_all',
          onAction: () => showAll++,
          child: TrustedStoreRail(
            stores: _stores,
            onTap: (store) => opened.add(store.family.slug),
          ),
        ),
      );

      final title = find.text('home_trusted_stores');
      final button = find.text('home_show_all');
      final firstCard = find.text('مطبخ أميرة');
      expect(tester.takeException(), isNull);
      expect(button, findsOneWidget);
      expect(
        tester.getCenter(button).dy,
        closeTo(tester.getCenter(title).dy, 2),
      );
      expect(
        tester.getTopLeft(button).dx,
        greaterThan(tester.getTopRight(title).dx - 1),
      );
      expect(
        tester.getBottomLeft(button).dy,
        lessThan(tester.getTopLeft(firstCard).dy),
      );

      await tester.tap(button);
      await tester.tap(firstCard);

      expect(showAll, 1);
      expect(opened, ['fam-1']);
    });

    testWidgets('the rail itself holds only the cards', (tester) async {
      await _pump(
        tester,
        TrustedStoreRail(stores: _stores, onTap: (_) {}),
      );

      expect(find.text('home_show_all'), findsNothing);
    });

    testWidgets('a section without an action has no button', (tester) async {
      await _pump(
        tester,
        HomeSection(
          title: 'home_trusted_stores',
          child: TrustedStoreRail(stores: _stores, onTap: (_) {}),
        ),
      );

      expect(find.text('home_show_all'), findsNothing);
    });

    testWidgets('every card has the same size whatever it shows',
        (tester) async {
      const long = 'وصف طويل جداً لا بد أن يلتف على أكثر من سطر واحد هنا وأكثر';
      const stores = [
        TrustedStore(
          family: FamilyRef(id: '1', name: 'قصير'),
          description: 'قصير',
        ),
        TrustedStore(
          family: FamilyRef(id: '2', name: 'طويل', isVerified: true),
          description: long,
        ),
        TrustedStore(
          family: FamilyRef(
            id: '3',
            name: 'مطبخ بمعلومات كاملة',
            city: 'الجيزة',
            rating: 4.6,
            productCount: 12,
            isVerified: true,
          ),
          description: long,
        ),
      ];

      await _pump(
        tester,
        TrustedStoreRail(stores: stores, onTap: (_) {}),
      );

      expect(tester.takeException(), isNull);
      final sizes = tester
          .widgetList<TrustedStoreCard>(find.byType(TrustedStoreCard))
          .map((card) => tester.getSize(find.byWidget(card)))
          .toSet();
      expect(sizes, {
        const Size(TrustedStoreCard.railWidth, TrustedStoreCard.height),
      });
    });

    testWidgets('a card fills the width it is given', (tester) async {
      await _pump(
        tester,
        TrustedStoreCard(store: _stores.first, onTap: () {}),
      );

      expect(tester.takeException(), isNull);
      final card = tester.getSize(find.byType(TrustedStoreCard));
      final page = tester.getSize(find.byType(ListView));
      expect(card.width, page.width);
    });
  });
}
