import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/paged.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/network_photo.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/data/models/catalog_models.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _family = FamilyProfile(
  id: 'fam_1',
  name: 'Umm Abdullah Family',
  story: 'A home kitchen in Hawalli since 2014.',
  city: 'Hawalli',
  isVerified: true,
  productCount: 24,
  rating: 4.9,
  followerCount: 1243,
);

ProductSummary _summary(String id, [String name = 'Cake']) => ProductSummary(
      id: id,
      name: name,
      family: const FamilyRef(id: 'fam_1', name: 'Umm Abdullah Family'),
      price: const Money(fils: 4250, display: '4.250 KWD'),
    );

Paged<ProductSummary> _page(List<String> ids, [String? next]) =>
    Paged(items: [for (final id in ids) _summary(id)], nextCursor: next);

class _FakeFamilyRepository implements FamilyRepository {
  Either<Failure, FamilyProfile> family = const Right(_family);
  final Map<String?, Either<Failure, Paged<ProductSummary>>> pages = {
    null: Right(_page(['prd_1', 'prd_2'], 'c2')),
    'c2': Right(_page(['prd_3'])),
  };
  final Map<String?, Completer<void>> gates = {};
  final List<String?> cursors = [];
  Completer<Either<Failure, bool>> follow = Completer();
  final List<bool> follows = [];

  @override
  Future<Either<Failure, FamilyProfile>> getFamily(String familyId) async =>
      family;

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String familyId, {
    String? cursor,
  }) async {
    cursors.add(cursor);
    await gates[cursor]?.future;
    return pages[cursor]!;
  }

  @override
  Future<Either<Failure, bool>> setFollowing(String familyId, bool following) {
    follows.add(following);
    return follow.future;
  }
}

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ));

void main() {
  group('FamilyProfileModel reads the contract', () {
    test('the fixture family parses whole', () {
      final family = FamilyProfileModel.fromJson(
        FixtureBackend().family('fam_1', 'en'),
      );

      expect(family.id, 'fam_1');
      expect(family.name, 'Umm Abdullah Family');
      expect(family.city, 'Hawalli');
      expect(family.story, isNotEmpty);
      expect(family.isVerified, isTrue);
      expect(family.cover?.url, 'assets/images/catalog/fam_1.jpg');
      expect(family.cover?.width, 1200);
      expect(family.avatar?.url, 'assets/images/catalog/fam_1_avatar.jpg');
      expect(family.productCount, 24);
      expect(family.rating, 4.9);
      expect(family.followerCount, 1243);
      expect(family.isFollowing, isFalse);
    });

    test('a followed family counts the customer', () {
      final family = FamilyProfileModel.fromJson(
        FixtureBackend().family('fam_3', 'en'),
      );

      expect(family.isFollowing, isTrue);
      expect(family.followerCount, 1419);
    });

    test('the cover and avatar are read when sent', () {
      final family = FamilyProfileModel.fromJson({
        'id': 'fam_1',
        'name': 'Family',
        'story': 'Story',
        'city': 'حولي',
        'is_verified': false,
        'cover': {'url': 'https://cdn/cover.jpg', 'width': 1200},
        'avatar': {'url': 'https://cdn/avatar.jpg'},
        'stats': {'product_count': 3, 'rating': 5, 'follower_count': 12},
        'is_following': true,
      });

      expect(family.cover?.url, 'https://cdn/cover.jpg');
      expect(family.cover?.width, 1200);
      expect(family.avatar?.url, 'https://cdn/avatar.jpg');
      expect(family.rating, 5.0);
      expect(family.isVerified, isFalse);
    });

    test('the products page is a cursor page', () {
      final page = ProductSummaryModel.pageFrom(
        FixtureBackend().familyProducts('fam_1', 'en'),
      );

      expect(page.items.length, 4);
      expect(page.items.first.family.id, 'fam_1');
      expect(page.hasMore, isFalse);
    });

    test('following moves the count by one and never below zero', () {
      expect(_family.withFollowing(true).followerCount, 1244);
      expect(_family.withFollowing(true).isFollowing, isTrue);
      expect(_family.withFollowing(false), same(_family));
      expect(
        const FamilyProfile(id: 'f', name: 'n', isFollowing: true)
            .withFollowing(false)
            .followerCount,
        0,
      );
    });
  });

  group('the mock data source through the repository', () {
    late FamilyRepositoryImpl repository;

    setUp(() {
      repository = FamilyRepositoryImpl(
        FamilyMockDataSource(FixtureBackend(), () async => 'en'),
      );
    });

    test('a family and its products come back', () async {
      final family = await repository.getFamily('fam_2');
      final products = await repository.getProducts('fam_2');

      expect(family.fold((_) => null, (f) => f.name), 'Bait Al Zafaran');
      expect(products.fold((_) => 0, (p) => p.items.length), 4);
    });

    test('a follow is kept by the backend', () async {
      final result = await repository.setFollowing('fam_1', true);
      final family = await repository.getFamily('fam_1');

      expect(result, const Right<Failure, bool>(true));
      family.fold((_) => fail('expected the family'), (f) {
        expect(f.isFollowing, isTrue);
        expect(f.followerCount, 1244);
      });
    });

    test('an unknown family is a not-found failure', () async {
      final family = await repository.getFamily('fam_missing');
      final products = await repository.getProducts('fam_missing');
      final follow = await repository.setFollowing('fam_missing', true);

      family.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'family_not_found');
        },
        (_) => fail('expected a failure'),
      );
      expect(products.fold((f) => f.message, (_) => null), 'family_not_found');
      expect(follow.isLeft(), isTrue);
    });
  });

  group('FamilyCubit', () {
    late _FakeFamilyRepository repository;
    late FamilyCubit cubit;

    setUp(() {
      repository = _FakeFamilyRepository();
      cubit = FamilyCubit(
        GetFamilyUseCase(repository),
        GetFamilyProductsUseCase(repository),
        SetFollowingUseCase(repository),
      );
    });

    tearDown(() => cubit.close());

    test('a load shows the family with its first page', () async {
      await cubit.load('fam_1');

      expect(cubit.state.status, FamilyStatus.loaded);
      expect(cubit.state.family, _family);
      expect(cubit.state.products.items.length, 2);
      expect(repository.cursors, [null]);
    });

    test('a failed family read is an error', () async {
      repository.family = const Left(NetworkFailure(message: 'offline'));

      await cubit.load('fam_1');

      expect(cubit.state.status, FamilyStatus.error);
      expect(cubit.state.errorMessage, 'offline');
    });

    test('a failed first page is an error too', () async {
      repository.pages[null] = const Left(ServerFailure(message: 'boom'));

      await cubit.load('fam_1');

      expect(cubit.state.status, FamilyStatus.error);
      expect(cubit.state.errorMessage, 'boom');
    });

    test('the next page is appended once, however often it is asked for',
        () async {
      await cubit.load('fam_1');
      repository.gates['c2'] = Completer();

      final first = cubit.loadMore();
      final second = cubit.loadMore();
      expect(cubit.state.isLoadingMore, isTrue);

      repository.gates['c2']!.complete();
      await Future.wait([first, second]);

      expect(repository.cursors, [null, 'c2']);
      expect(cubit.state.products.items.map((p) => p.id),
          ['prd_1', 'prd_2', 'prd_3']);
      expect(cubit.state.products.hasMore, isFalse);

      await cubit.loadMore();
      expect(repository.cursors, [null, 'c2']);
    });

    test('a failed next page keeps the list and reports', () async {
      await cubit.load('fam_1');
      repository.pages['c2'] = const Left(NetworkFailure(message: 'offline'));

      await cubit.loadMore();

      expect(cubit.state.status, FamilyStatus.loaded);
      expect(cubit.state.products.items.length, 2);
      expect(cubit.state.errorMessage, 'offline');
      expect(cubit.state.isLoadingMore, isFalse);
    });

    test('a page from before a reload is dropped', () async {
      await cubit.load('fam_1');
      repository.gates['c2'] = Completer();

      final stale = cubit.loadMore();
      await cubit.load('fam_1');
      repository.gates['c2']!.complete();
      await stale;

      expect(cubit.state.products.items.length, 2);
      expect(cubit.state.isLoadingMore, isFalse);
    });

    test('a follow shows at once and moves the count', () async {
      await cubit.load('fam_1');

      final toggle = cubit.toggleFollow();
      expect(cubit.state.family?.isFollowing, isTrue);
      expect(cubit.state.family?.followerCount, 1244);

      cubit.toggleFollow();
      expect(repository.follows, [true]);

      repository.follow.complete(const Right(true));
      await toggle;

      expect(cubit.state.family?.isFollowing, isTrue);
      expect(cubit.state.isSavingFollow, isFalse);
    });

    test('a refused follow rolls back and reports', () async {
      await cubit.load('fam_1');

      final toggle = cubit.toggleFollow();
      repository.follow.complete(
        const Left(ServerFailure(message: 'follow_failed')),
      );
      await toggle;

      expect(cubit.state.family?.isFollowing, isFalse);
      expect(cubit.state.family?.followerCount, 1243);
      expect(cubit.state.errorMessage, 'follow_failed');
      expect(cubit.state.status, FamilyStatus.loaded);
    });
  });

  group('family widgets', () {
    test('followers read compact, one decimal, lower case', () {
      expect(FamilyStats.compact(1243), '1.2k');
      expect(FamilyStats.compact(1418), '1.4k');
      expect(FamilyStats.compact(862), '862');
      expect(FamilyStats.compact(12430), '12.4k');
      expect(FamilyStats.compact(1243000), '1.2m');
    });

    testWidgets('the header lays out and follows on tap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        FamilyHeader(family: _family, onFollow: () => taps++),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Umm Abdullah Family'), findsOneWidget);
      expect(find.text('Hawalli · family_verified'), findsOneWidget);

      await tester.tap(find.text('family_follow'));
      expect(taps, 1);

      final photos = find.byType(NetworkPhoto);
      final cover = tester.getRect(photos.first);
      final avatar = tester.getRect(photos.last);
      expect(cover.height, FamilyHeader.coverHeight);
      expect(avatar.top, lessThan(cover.bottom));
    });

    testWidgets('a product row keeps two cards level without overflow',
        (tester) async {
      await _pump(
        tester,
        FamilyProductRow(
          products: [
            _summary('prd_1', 'Cardamom date cake with saffron and rose'),
            _summary('prd_2', 'Bread'),
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
