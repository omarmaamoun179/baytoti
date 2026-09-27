import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../models/family_profile_model.dart';

abstract class FamilyDataSource {
  Future<Either<Failure, FamilyProfileModel>> getFamily(String familyId);

  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String familyId, {
    int? page,
  });

  Future<Either<Failure, bool>> setFollowing(String familyId, bool following);
}

const Map<int, String> _familyRenames = {404: 'family_not_found'};

class FamilyRemoteDataSource implements FamilyDataSource {
  final NetworkService _network;

  FamilyRemoteDataSource(this._network);

  @override
  Future<Either<Failure, FamilyProfileModel>> getFamily(String familyId) =>
      guardedRequest(
        'FamilyRemoteDataSource.getFamily',
        () async {
          final response = await _network.get(ApiEndPoint.family(familyId));
          return FamilyProfileModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'family_failed',
        messageForStatus: _familyRenames,
      );

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String familyId, {
    int? page,
  }) =>
      guardedRequest(
        'FamilyRemoteDataSource.getProducts',
        () async {
          final response = await _network.get(
            ApiEndPoint.familyProducts(familyId),
            queryParameters: {'page': ?page},
          );
          return ProductSummaryModel.pageFrom(checkedResponse(response).json);
        },
        fallbackMessage: 'family_failed',
        messageForStatus: _familyRenames,
      );

  @override
  Future<Either<Failure, bool>> setFollowing(
    String familyId,
    bool following,
  ) =>
      guardedRequest(
        'FamilyRemoteDataSource.setFollowing',
        () async {
          final url = ApiEndPoint.familyFollow(familyId);
          final response = following
              ? await _network.post(url)
              : await _network.delete(url);
          final json = checkedResponse(response).json;
          return json['is_following'] as bool? ?? following;
        },
        fallbackMessage: 'follow_failed',
      );
}

class FamilyMockDataSource implements FamilyDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  FamilyMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, FamilyProfileModel>> getFamily(String familyId) =>
      guardedRequest(
        'FamilyMockDataSource.getFamily',
        () async {
          await _backend.wait();
          return FamilyProfileModel.fromJson(
            _backend.family(familyId, await _language()),
          );
        },
        fallbackMessage: 'family_failed',
        messageForStatus: _familyRenames,
      );

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String familyId, {
    int? page,
  }) =>
      guardedRequest(
        'FamilyMockDataSource.getProducts',
        () async {
          await _backend.wait();
          return ProductSummaryModel.pageFrom(
            _backend.familyProducts(familyId, await _language()),
          );
        },
        fallbackMessage: 'family_failed',
        messageForStatus: _familyRenames,
      );

  @override
  Future<Either<Failure, bool>> setFollowing(
    String familyId,
    bool following,
  ) =>
      guardedRequest(
        'FamilyMockDataSource.setFollowing',
        () async {
          await _backend.wait();
          _backend.follow(
            familyId,
            following: following,
            lang: await _language(),
          );
          return following;
        },
        fallbackMessage: 'follow_failed',
      );
}
