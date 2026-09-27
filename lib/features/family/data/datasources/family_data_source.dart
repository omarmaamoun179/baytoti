import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../models/family_profile_model.dart';

abstract class FamilyDataSource {
  Future<Either<Failure, FamilyProfileModel>> getFamily(String slug);

  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String slug, {
    int? page,
  });
}

const Map<int, String> _familyRenames = {404: 'family_not_found'};

class FamilyRemoteDataSource implements FamilyDataSource {
  final NetworkService _network;

  FamilyRemoteDataSource(this._network);

  @override
  Future<Either<Failure, FamilyProfileModel>> getFamily(String slug) =>
      guardedRequest(
        'FamilyRemoteDataSource.getFamily',
        () async {
          final response = await _network.get(ApiEndPoint.store(slug));
          return FamilyProfileModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'family_failed',
        messageForStatus: _familyRenames,
      );

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String slug, {
    int? page,
  }) =>
      guardedRequest(
        'FamilyRemoteDataSource.getProducts',
        () async {
          final response = await _network.get(
            ApiEndPoint.products,
            queryParameters: {
              'store': slug,
              'page': ?page,
              'per_page': defaultPageSize,
            },
          );
          final json = checkedResponse(response).json;
          if (json['data'] is! List) {
            throw const FormatException('the products answer has no list');
          }
          return ProductSummaryModel.pageFrom(json);
        },
        fallbackMessage: 'family_failed',
      );
}
