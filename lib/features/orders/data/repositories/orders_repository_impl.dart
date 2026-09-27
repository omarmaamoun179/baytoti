import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_data_source.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersDataSource _dataSource;

  OrdersRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Paged<OrderSummary>>> getOrders(OrdersQuery query) =>
      _dataSource.getOrders(query);

  @override
  Future<Either<Failure, OrderDetail>> getOrder(String id) =>
      _dataSource.getOrder(id);

  @override
  Future<Either<Failure, Unit>> rateOrder(RateOrderParams params) =>
      _dataSource.rateOrder(params);
}
