import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../domain/entities/order.dart';
import '../models/order_models.dart';

const Map<int, String> _orderMissing = {404: 'order_not_found'};

abstract class OrdersDataSource {
  Future<Either<Failure, Paged<OrderSummary>>> getOrders(OrdersQuery query);

  Future<Either<Failure, OrderDetailModel>> getOrder(String id);
}

class OrdersRemoteDataSource implements OrdersDataSource {
  final NetworkService _network;

  OrdersRemoteDataSource(this._network);

  @override
  Future<Either<Failure, Paged<OrderSummary>>> getOrders(OrdersQuery query) =>
      guardedRequest(
        'OrdersRemoteDataSource.getOrders',
        () async {
          final response = await _network.get(
            ApiEndPoint.orders,
            queryParameters: query.toQueryParameters(),
          );
          return OrderSummaryModel.pageFrom(checkedResponse(response).json);
        },
        fallbackMessage: 'order_failed',
      );

  @override
  Future<Either<Failure, OrderDetailModel>> getOrder(String id) =>
      guardedRequest(
        'OrdersRemoteDataSource.getOrder',
        () async {
          final response = await _network.get(ApiEndPoint.order(id));
          return OrderDetailModel.fromResponse(checkedResponse(response));
        },
        fallbackMessage: 'order_failed',
        messageForStatus: _orderMissing,
      );
}
