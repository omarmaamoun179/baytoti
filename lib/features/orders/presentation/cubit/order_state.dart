import 'package:equatable/equatable.dart';

import '../../../product/domain/entities/product_detail.dart';
import '../../domain/entities/order.dart';

enum OrderViewStatus { initial, loading, loaded, empty, error }

class OrderState extends Equatable {
  final OrderViewStatus status;
  final OrderDetail? order;
  final bool isCancelling;
  final Map<String, Review> reviews;
  final String? errorMessage;

  const OrderState({
    this.status = OrderViewStatus.initial,
    this.order,
    this.isCancelling = false,
    this.reviews = const {},
    this.errorMessage,
  });

  bool get canCancel => order?.status?.isCancellable ?? false;

  bool get canReview => order?.status?.isReviewable ?? false;

  OrderState copyWith({
    OrderViewStatus? status,
    OrderDetail? order,
    bool? isCancelling,
    Map<String, Review>? reviews,
    String? errorMessage,
  }) {
    return OrderState(
      status: status ?? this.status,
      order: order ?? this.order,
      isCancelling: isCancelling ?? this.isCancelling,
      reviews: reviews ?? this.reviews,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, order, isCancelling, reviews, errorMessage];
}
