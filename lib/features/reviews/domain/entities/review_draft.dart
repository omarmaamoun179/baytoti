import 'package:equatable/equatable.dart';

class ReviewDraft extends Equatable {
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int commentMaxLength = 2000;

  final String productId;
  final String? orderId;
  final String? reviewId;
  final int rating;
  final String comment;

  const ReviewDraft({
    required this.productId,
    this.orderId,
    this.reviewId,
    required this.rating,
    this.comment = '',
  });

  bool get isEdit => reviewId != null;

  @override
  List<Object?> get props => [productId, orderId, reviewId, rating, comment];
}
