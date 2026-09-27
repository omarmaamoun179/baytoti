import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/domain/entities/category.dart';
import 'package:baytoti/features/catalog/domain/entities/product_badge.dart';
import 'package:baytoti/features/home/data/datasources/home_data_source.dart';
import 'package:baytoti/features/home/data/models/home_feed_model.dart';
import 'package:baytoti/features/home/data/repositories/home_repository_impl.dart';
import 'package:baytoti/features/home/domain/usecases/get_home_use_case.dart';
import 'package:baytoti/features/home/presentation/cubit/home_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingHome implements HomeDataSource {
  @override
  Future<Either<Failure, HomeFeedModel>> getHome() async =>
      const Left(NetworkFailure(message: 'offline'));
}

void main() {
  group('GET /home as the contract shapes it', () {
    test('parses every section in Arabic', () {
      final feed = HomeFeedModel.fromJson(FixtureBackend().home('ar'));

      expect(feed.banner?.title, 'معرض بيتوتي الخريفي');
      expect(feed.banner?.actionLabel, 'امسح رمز الجناح');
      expect(feed.categories.map((c) => c.icon), CategoryIcon.values);
      expect(feed.featuredFamilies, hasLength(4));
      expect(feed.featuredFamilies.first.isVerified, isTrue);
      expect(feed.bestSellers, hasLength(6));
      expect(feed.bestSellers.first.badge, ProductBadge.bestSeller);
      expect(feed.bestSellers.first.price.display, '4.250 د.ك');
      expect(feed.bestSellers.first.family.name, 'أسرة أم عبدالله');
    });

    test('answers in the language asked for', () {
      final feed = HomeFeedModel.fromJson(FixtureBackend().home('en'));

      expect(feed.bestSellers.first.name, 'Cardamom date cake');
      expect(feed.bestSellers.first.price.display, '4.250 د.ك');
    });
  });

  group('HomeCubit', () {
    test('loads the feed', () async {
      final cubit = HomeCubit(GetHomeUseCase(HomeRepositoryImpl(
        HomeMockDataSource(FixtureBackend(), () async => 'ar'),
      )));

      await cubit.load();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.feed?.bestSellers, isNotEmpty);
      await cubit.close();
    });

    test('a first failure is an error screen with the message', () async {
      final cubit = HomeCubit(GetHomeUseCase(HomeRepositoryImpl(_FailingHome())));

      await cubit.load();

      expect(cubit.state.status, HomeStatus.error);
      expect(cubit.state.errorMessage, 'offline');
      await cubit.close();
    });
  });
}
