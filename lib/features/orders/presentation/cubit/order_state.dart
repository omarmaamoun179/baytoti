import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';

enum OrderViewStatus { initial, loading, loaded, empty, error }

class OrderState extends Equatable {
  final OrderViewStatus status;
  final OrderDetail? order;
  final String? errorMessage;

  const OrderState({
    this.status = OrderViewStatus.initial,
    this.order,
    this.errorMessage,
  });

  OrderState copyWith({
    OrderViewStatus? status,
    OrderDetail? order,
    String? errorMessage,
  }) {
    return OrderState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, order, errorMessage];
}
