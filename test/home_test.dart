import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/brand_mark.dart';
import 'package:baytoti/features/catalog/domain/entities/category.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_badge.dart';
import 'package:baytoti/features/home/data/datasources/home_data_source.dart';
import 'package:baytoti/features/home/data/models/home_feed_model.dart';
import 'package:baytoti/features/home/data/repositories/home_repository_impl.dart';
import 'package:baytoti/features/home/domain/entities/home_feed.dart';
import 'package:baytoti/features/home/domain/usecases/get_home_use_case.dart';
import 'package:baytoti/features/home/presentation/cubit/home_cubit.dart';
import 'package:baytoti/features/home/presentation/widgets/category_rail.dart';
import 'package:baytoti/features/home/presentation/widgets/home_banner_strip.dart';
import 'package:baytoti/features/home/presentation/widgets/promotion_rail.dart';
import 'package:baytoti/features/home/presentation/widgets/trusted_store_rail.dart';
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
  }) async {
    calls.add(FakeCall('GET', url, queryParameters, null, headers));
    throw const ConnectionException();
  }
}

HomeRepositoryImpl _repository(FakeNetwork network) =>
    HomeRepositoryImpl(HomeRemoteDataSource(network));

Future<HomeFeed> _feedFrom(String sample) async {
  final network = FakeNetwork()..replySample('GET', ApiEndPoint.home, sample);
  return (await _repository(network).getHome())
      .getOrElse(() => throw StateError('refused'));
}

Future<Failure> _failureOf(FakeNetwork network) async =>
    (await _repository(network).getHome())
        .fold((failure) => failure, (_) => throw StateError('accepted'));

void main() {
  group('GET /home as Betouti answers it', () {
    test('asks the one endpoint and reads every live section', () async {
      final network = FakeNetwork()
        ..replySample('GET', ApiEndPoint.home, 'betouti/home.json');

      final feed = (await _repository(network).getHome())
          .getOrElse(() => throw StateError('refused'));

      expect(network.calls.single.url, ApiEndPoint.home);
      expect(network.calls.single.query, isNull);

      final banner = feed.banners.first;
      expect(feed.banners, hasLength(3));
      expect(banner.id, '1');
      expect(banner.title, 'أكل بيتي بطعم زمان');
      expect(banner.subtitle, 'اكتشف أكلات الأسر المنتجة في منطقتك');
      expect(banner.actionLabel, 'اكتشف الآن');
      expect(banner.imageUrl, contains('photo-1504674900247'));
      expect(banner.discountLabel, isNull);
      expect(
        banner.target,
        const HomeTarget(kind: HomeTargetKind.category, id: '1'),
      );

      expect(feed.categories, hasLength(10));
      expect(feed.categories.first.id, '1');
      expect(feed.categories.first.slug, 'home-cooked-food');
      expect(feed.categories.first.name, 'الأكل البيتي');
      expect(feed.categories.first.imageUrl, contains('photo-1547592180'));

      final family = feed.trustedStores.first;
      expect(feed.trustedStores, hasLength(4));
      expect(family.family.id, '1');
      expect(family.family.slug, 'mtbkh-amyr-1');
      expect(family.family.name, 'مطبخ أميرة');
      expect(family.family.isVerified, isTrue);
      expect(family.family.images.single.url, contains('photo-1556910103'));
      expect(family.bannerUrl, contains('photo-1556911220'));
      expect(family.description, startsWith('أكلات بيتية'));

      expect(feed.featuredProducts, isEmpty);

      expect(feed.promotions, hasLength(3));
      expect(feed.promotions.first.title, 'خصم حتى 20%');
      expect(feed.promotions.first.discountLabel, '20%');
      expect(feed.promotions.first.actionLabel, 'اطلب الآن');
    });

    test('every banner and promotion opens a category from the same feed',
        () async {
      final feed = await _feedFrom('betouti/home.json');

      expect(
        [for (final banner in feed.banners) feed.slugOf(banner.target)],
        ['home-cooked-food', 'main-dishes', 'desserts'],
      );
      expect(
        [for (final promo in feed.promotions) feed.slugOf(promo.target)],
        ['main-dishes', 'desserts', 'breakfast'],
      );
    });
  });

  group('featured products in the engine\'s /home shape', () {
    test('a string price, its compare price and image_url are read',
        () async {
      final feed = await _feedFrom('home/home.cloak.json');
      final product = feed.featuredProducts.first;

      expect(feed.featuredProducts, hasLength(10));
      expect(product.id, '13');
      expect(product.slug, 'aabay-dyzrt-mlky-3');
      expect(product.name, 'عباية ديزرت ملكي 3');
      expect(product.price.fils, 38000);
      expect(product.compareAt?.fils, 45000);
      expect(product.images.single.url, contains('photo-1515886657613'));
      expect(product.badge, ProductBadge.featured);
      expect(product.family.name, isEmpty);
    });

    test('targets resolve to products and families by their slugs',
        () async {
      final feed = await _feedFrom('home/home.cloak.json');

      expect(
        feed.slugOf(const HomeTarget(kind: HomeTargetKind.product, id: '13')),
        'aabay-dyzrt-mlky-3',
      );
      expect(
        feed.slugOf(const HomeTarget(kind: HomeTargetKind.family, id: '1')),
        'dar-lm-1',
      );
      expect(
        feed.slugOf(const HomeTarget(kind: HomeTargetKind.category, id: '99')),
        isNull,
      );
      expect(feed.slugOf(null), isNull);
    });
  });

  group('a payload the app does not expect', () {
    test('missing or malformed sections read as empty', () {
      final feed = HomeFeedModel.fromJson(const {
        'banners': 'soon',
        'categories': null,
        'featured_products': [1, 'two'],
      });

      expect(feed.banners, isEmpty);
      expect(feed.categories, isEmpty);
      expect(feed.trustedStores, isEmpty);
      expect(feed.featuredProducts, isEmpty);
      expect(feed.promotions, isEmpty);
    });

    test('an unknown or broken target costs the banner its tap only', () {
      HomeBanner banner(Object? target) => HomeBannerModel.fromJson({
            'id': 7,
            'title': 'عرض',
            'cta_label': '',
            'image_url': null,
            'target': target,
          });

      expect(banner({'entity': 'brand', 'entity_id': 1}).target, isNull);
      expect(banner({'entity': 'category'}).target, isNull);
      expect(banner('category').target, isNull);
      expect(
        banner({'entity': 'store', 'entity_id': 4}).target,
        const HomeTarget(kind: HomeTargetKind.family, id: '4'),
      );
      expect(banner(null).title, 'عرض');
      expect(banner(null).actionLabel, isNull);
      expect(banner(null).imageUrl, isNull);
    });

    test('the mobile image wins over the wide one', () {
      final banner = HomeBannerModel.fromJson(const {
        'id': 1,
        'title': 't',
        'image_url': 'https://img/wide.jpg',
        'mobile_image_url': 'https://img/tall.jpg',
      });

      expect(banner.imageUrl, 'https://img/tall.jpg');
    });
  });

  group('when /home fails', () {
    test('a 500 is a server failure with the generic message', () async {
      final network = FakeNetwork()
        ..replySample(
          'GET',
          ApiEndPoint.home,
          'betouti/products_guest_500.json',
          status: 500,
        );

      final failure = await _failureOf(network);

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 500);
      expect(failure.message, 'server_error');
    });

    test('a 401 is refused, not parsed', () async {
      final network = FakeNetwork()
        ..replySample(
          'GET',
          ApiEndPoint.home,
          'betouti/unauthenticated_401.json',
          status: 401,
        );

      final failure = await _failureOf(network);

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
      expect(failure.message, 'Unauthenticated.');
    });

    test('offline is a retryable network failure', () async {
      final failure = await _failureOf(_OfflineNetwork());

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'connection_failed');
    });
  });

  group('HomeCubit', () {
    HomeCubit cubitOn(FakeNetwork network) =>
        HomeCubit(GetHomeUseCase(_repository(network)));

    test('loads the feed', () async {
      final network = FakeNetwork()
        ..replySample('GET', ApiEndPoint.home, 'betouti/home.json');
      final cubit = cubitOn(network);

      await cubit.load();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.feed?.banners, hasLength(3));
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('a first failure is an error screen with the message', () async {
      final cubit = cubitOn(_OfflineNetwork());

      await cubit.load();

      expect(cubit.state.status, HomeStatus.error);
      expect(cubit.state.feed, isNull);
      expect(cubit.state.errorMessage, 'connection_failed');
      await cubit.close();
    });

    test('a failed refresh keeps the feed and says why', () async {
      final network = FakeNetwork()
        ..replySample('GET', ApiEndPoint.home, 'betouti/home.json');
      final cubit = cubitOn(network);
      await cubit.load();

      network.replySample(
        'GET',
        ApiEndPoint.home,
        'betouti/products_guest_500.json',
        status: 500,
      );
      await cubit.load();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.feed?.categories, hasLength(10));
      expect(cubit.state.errorMessage, 'server_error');
      expect(network.calls, hasLength(2));
      await cubit.close();
    });
  });

  group('home widgets', () {
    Future<void> pump(WidgetTester tester, List<Widget> children) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ScreenUtilScope(
        child: Builder(
          builder: (_) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: ListView(children: children)),
          ),
        ),
      ));
    }

    testWidgets('banners, categories, trusted stores and offers lay out and tap',
        (tester) async {
      final taps = <String>[];
      const long = 'عنوان طويل جداً لا بد أن يلتف على أكثر من سطر واحد هنا';
      const banners = [
        HomeBanner(id: '1', title: long, subtitle: long, actionLabel: 'اكتشف'),
        HomeBanner(id: '2', title: 'ثاني'),
      ];
      const promotions = [
        HomeBanner(
          id: '3',
          title: long,
          subtitle: long,
          discountLabel: '20%',
          actionLabel: 'اطلب الآن',
        ),
      ];
      const stores = [
        TrustedStore(
          family: FamilyRef(
            id: '1',
            slug: 'fam-1',
            name: 'مطبخ أميرة',
            isVerified: true,
          ),
          description: long,
        ),
      ];
      const categories = [
        Category(
          id: '5',
          slug: 'desserts',
          name: 'الحلويات',
          icon: CategoryIcon.sweets,
        ),
      ];

      await pump(tester, [
        HomeBannerStrip(
          banners: banners,
          onTap: (banner) => taps.add('banner ${banner.id}'),
        ),
        CategoryRail(categories: categories, onTap: (c) => taps.add(c.slug)),
        TrustedStoreRail(
          stores: stores,
          onTap: (store) => taps.add(store.family.slug),
        ),
        PromotionRail(
          promotions: promotions,
          onTap: (promotion) => taps.add('promo ${promotion.id}'),
        ),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.byType(VerifiedBadge), findsOneWidget);
      expect(find.text('اكتشف'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);

      await tester.tap(find.text('اكتشف'));
      await tester.tap(find.text('الحلويات'));
      await tester.tap(find.text('مطبخ أميرة'));
      await tester.tap(find.text('20%'));

      expect(taps, ['banner 1', 'desserts', 'fam-1', 'promo 3']);
    });
  });
}
