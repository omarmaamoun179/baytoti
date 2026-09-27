import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../domain/entities/search_query.dart';

abstract class SearchDataSource {
  Future<Either<Failure, Paged<ProductSummary>>> search(SearchQuery query);

  Future<Either<Failure, List<Category>>> getCategories();
}

class SearchRemoteDataSource implements SearchDataSource {
  final NetworkService _network;

  SearchRemoteDataSource(this._network);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> search(SearchQuery query) =>
      guardedRequest(
        'SearchRemoteDataSource.search',
        () async {
          final response = await _network.get(
            ApiEndPoint.products,
            queryParameters: query.toQueryParameters(),
          );
          return ProductSummaryModel.pageFrom(checkedResponse(response).json);
        },
        fallbackMessage: 'search_failed',
      );

  @override
  Future<Either<Failure, List<Category>>> getCategories() => guardedRequest(
        'SearchRemoteDataSource.getCategories',
        () async {
          final response = await _network.get(ApiEndPoint.activeCategories);
          return CategoryModel.listFrom(checkedResponse(response).json['data']);
        },
        fallbackMessage: 'search_failed',
      );
}
