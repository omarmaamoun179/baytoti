import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class GetOrdersUseCase
    implements UseCase<Either<Failure, Paged<OrderSummary>>, OrdersQuery> {
  final OrdersRepository _repository;

  GetOrdersUseCase(this._repository);

  @override
  Future<Either<Failure, Paged<OrderSummary>>> call(OrdersQuery params) =>
      _repository.getOrders(params);
}

class GetOrderUseCase implements UseCase<Either<Failure, OrderDetail>, String> {
  final OrdersRepository _repository;

  GetOrderUseCase(this._repository);

  @override
  Future<Either<Failure, OrderDetail>> call(String orderId) =>
      _repository.getOrder(orderId);
}
