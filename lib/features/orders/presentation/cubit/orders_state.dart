import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../domain/entities/order.dart';

enum OrdersStatus { initial, loading, loaded, error }

class OrdersState extends Equatable {
  final OrdersStatus status;
  final Paged<OrderSummary> page;
  final bool isLoadingMore;
  final String? errorMessage;

  const OrdersState({
    this.status = OrdersStatus.initial,
    this.page = const Paged<OrderSummary>(),
    this.isLoadingMore = false,
    this.errorMessage,
  });

  List<OrderSummary> get orders => page.items;

  bool get isLoaded => status == OrdersStatus.loaded;

  OrdersState copyWith({
    OrdersStatus? status,
    Paged<OrderSummary>? page,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return OrdersState(
      status: status ?? this.status,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, page, isLoadingMore, errorMessage];
}
