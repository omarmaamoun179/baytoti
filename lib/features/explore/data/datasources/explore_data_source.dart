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
import '../../domain/entities/explore_tab.dart';

abstract class ExploreDataSource {
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    ExploreTab tab, {
    int page = 1,
  });
}

class ExploreRemoteDataSource implements ExploreDataSource {
  final NetworkService _network;

  ExploreRemoteDataSource(this._network);

  static Map<String, dynamic> _queryFor(ExploreTab tab, int page) => {
        'sort': ?tab.sort,
        if (tab.featuredOnly) 'featured': 1,
        'page': page,
        'per_page': defaultPageSize,
      };

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    ExploreTab tab, {
    int page = 1,
  }) =>
      guardedRequest(
        'ExploreRemoteDataSource.getProducts',
        () async {
          final response = await _network.get(
            ApiEndPoint.products,
            queryParameters: _queryFor(tab, page),
          );
          return ProductSummaryModel.pageFrom(checkedResponse(response).json);
        },
        fallbackMessage: 'explore_failed',
      );
}
