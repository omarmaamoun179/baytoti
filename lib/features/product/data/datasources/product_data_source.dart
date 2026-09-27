import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../domain/entities/product_detail.dart';
import '../models/product_detail_model.dart';

abstract class ProductDataSource {
  Future<Either<Failure, ProductDetailModel>> getProduct(String slug);

  Future<Either<Failure, List<Review>>> getReviews(String productId);
}

const Map<int, String> _productRenames = {404: 'product_not_found'};

class ProductRemoteDataSource implements ProductDataSource {
  static const int reviewPreviewSize = 3;

  final NetworkService _network;

  ProductRemoteDataSource(this._network);

  @override
  Future<Either<Failure, ProductDetailModel>> getProduct(String slug) =>
      guardedRequest(
        'ProductRemoteDataSource.getProduct',
        () async {
          final response = await _network.get(ApiEndPoint.product(slug));
          return ProductDetailModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'product_failed',
        messageForStatus: _productRenames,
      );

  @override
  Future<Either<Failure, List<Review>>> getReviews(String productId) =>
      guardedRequest(
        'ProductRemoteDataSource.getReviews',
        () async {
          final response = await _network.get(
            ApiEndPoint.productReviews(productId),
            queryParameters: {'page': 1, 'per_page': reviewPreviewSize},
          );
          final json = checkedResponse(response).json;
          if (json['data'] is! List) {
            throw const FormatException('the reviews answer has no list');
          }
          return ReviewModel.listFrom(json['data']);
        },
        fallbackMessage: 'product_failed',
        messageForStatus: _productRenames,
      );
}
