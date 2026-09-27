import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';

enum OrderViewStatus { initial, loading, loaded, empty, error }

enum RatingStatus { idle, submitting, succeeded, failed }

class OrderState extends Equatable {
  final OrderViewStatus status;
  final OrderDetail? order;
  final RatingStatus ratingStatus;
  final int rating;
  final String? errorMessage;

  const OrderState({
    this.status = OrderViewStatus.initial,
    this.order,
    this.ratingStatus = RatingStatus.idle,
    this.rating = 0,
    this.errorMessage,
  });

  bool get isRating => ratingStatus == RatingStatus.submitting;

  bool get showsRating =>
      (order?.canRate ?? false) && ratingStatus != RatingStatus.succeeded;

  OrderState copyWith({
    OrderViewStatus? status,
    OrderDetail? order,
    RatingStatus? ratingStatus,
    int? rating,
    String? errorMessage,
  }) {
    return OrderState(
      status: status ?? this.status,
      order: order ?? this.order,
      ratingStatus: ratingStatus ?? this.ratingStatus,
      rating: rating ?? this.rating,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, order, ratingStatus, rating, errorMessage];
}
