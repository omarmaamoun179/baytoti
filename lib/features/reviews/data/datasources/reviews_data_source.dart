import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json.dart';
import '../../../product/data/models/product_detail_model.dart';
import '../../domain/entities/review_draft.dart';

abstract class ReviewsDataSource {
  Future<Either<Failure, ReviewModel>> submit(ReviewDraft draft);
}

class ReviewsRemoteDataSource implements ReviewsDataSource {
  final NetworkService _network;

  ReviewsRemoteDataSource(this._network);

  @override
  Future<Either<Failure, ReviewModel>> submit(ReviewDraft draft) =>
      guardedRequest(
        'ReviewsRemoteDataSource.submit',
        () async {
          final comment = draft.comment.trim();
          final reviewId = draft.reviewId;
          final orderId = draft.orderId;

          final response = reviewId == null
              ? await _network.post(
                  ApiEndPoint.reviews,
                  data: {
                    'product_id': _wireId(draft.productId),
                    if (orderId != null) 'order_id': _wireId(orderId),
                    'rating': draft.rating,
                    if (comment.isNotEmpty) 'comment': comment,
                  },
                )
              : await _network.patch(
                  ApiEndPoint.review(reviewId),
                  data: {
                    'rating': draft.rating,
                    'comment': comment.isEmpty ? null : comment,
                  },
                );

          final json = checkedResponse(response).json;
          final answered =
              ReviewModel.fromJson(jsonMapOrNull(json['review']) ?? json);
          return answered.id.isEmpty
              ? ReviewModel(
                  id: reviewId ?? '',
                  authorName: '',
                  rating: draft.rating,
                  body: comment,
                )
              : answered;
        },
        fallbackMessage: 'review_failed',
        messageForStatus: const {403: 'review_not_allowed'},
      );

  Object _wireId(String id) => int.tryParse(id) ?? id;
}
