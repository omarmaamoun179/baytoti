import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../domain/entities/product_detail.dart';
import '../models/product_detail_model.dart';

abstract class ProductDataSource {
  Future<Either<Failure, ProductDetailModel>> getProduct(String slug);

  Future<Either<Failure, ReviewDigest>> getReviews(ReviewsQuery query);
}

const Map<int, String> _productRenames = {404: 'product_not_found'};

class ProductRemoteDataSource implements ProductDataSource {
  static const int reviewPreviewSize = 3;
  static const int reviewPageSize = 100;
  static const int reviewScanPages = 5;

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
  Future<Either<Failure, ReviewDigest>> getReviews(ReviewsQuery query) =>
      guardedRequest(
        'ProductRemoteDataSource.getReviews',
        () async {
          final authorId = query.authorId;
          var page = await _reviewPage(query.productId, 1);
          final latest = page.items.take(reviewPreviewSize).toList();
          var mine = _authoredBy(page.items, authorId);

          while (mine == null &&
              authorId != null &&
              page.hasMore &&
              page.currentPage < reviewScanPages) {
            page = await _reviewPage(query.productId, page.nextPage);
            mine = _authoredBy(page.items, authorId);
          }
          return ReviewDigest(latest: latest, mine: mine);
        },
        fallbackMessage: 'product_failed',
        messageForStatus: _productRenames,
      );

  Future<Paged<Review>> _reviewPage(String productId, int page) async {
    final response = await _network.get(
      ApiEndPoint.productReviews(productId),
      queryParameters: {'page': page, 'per_page': reviewPageSize},
    );
    final json = checkedResponse(response).json;
    if (json['data'] is! List) {
      throw const FormatException('the reviews answer has no list');
    }
    return Paged.fromJson(json, ReviewModel.fromJson);
  }

  Review? _authoredBy(List<Review> reviews, String? authorId) => authorId == null
      ? null
      : reviews.where((review) => review.authorId == authorId).firstOrNull;
}
