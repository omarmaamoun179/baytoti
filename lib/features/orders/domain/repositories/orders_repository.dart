import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../entities/order.dart';

abstract class OrdersRepository {
  Future<Either<Failure, Paged<OrderSummary>>> getOrders(OrdersQuery query);

  Future<Either<Failure, OrderDetail>> getOrder(String id);

  Future<Either<Failure, OrderDetail>> cancelOrder(String id);
}
