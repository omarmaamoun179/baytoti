import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';

enum OrderViewStatus { initial, loading, loaded, empty, error }

class OrderState extends Equatable {
  final OrderViewStatus status;
  final OrderDetail? order;
  final bool isCancelling;
  final String? errorMessage;

  const OrderState({
    this.status = OrderViewStatus.initial,
    this.order,
    this.isCancelling = false,
    this.errorMessage,
  });

  bool get canCancel => order?.status?.isCancellable ?? false;

  OrderState copyWith({
    OrderViewStatus? status,
    OrderDetail? order,
    bool? isCancelling,
    String? errorMessage,
  }) {
    return OrderState(
      status: status ?? this.status,
      order: order ?? this.order,
      isCancelling: isCancelling ?? this.isCancelling,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, order, isCancelling, errorMessage];
}
