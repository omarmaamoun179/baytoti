import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../../domain/entities/order.dart';
import '../models/order_models.dart';

const Map<int, String> _orderMissing = {404: 'order_not_found'};

abstract class OrdersDataSource {
  Future<Either<Failure, Paged<OrderSummary>>> getOrders(OrdersQuery query);

  Future<Either<Failure, OrderDetailModel>> getOrder(String id);

  Future<Either<Failure, Unit>> rateOrder(RateOrderParams params);
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
          return OrderDetailModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'order_failed',
        messageForStatus: _orderMissing,
      );

  @override
  Future<Either<Failure, Unit>> rateOrder(RateOrderParams params) =>
      guardedRequest(
        'OrdersRemoteDataSource.rateOrder',
        () async {
          checkedResponse(await _network.post(
            ApiEndPoint.orderRating(params.orderId),
            data: {'rating': params.rating},
          ));
          return unit;
        },
        fallbackMessage: 'rating_failed',
        messageForStatus: _orderMissing,
      );
}

class OrdersMockDataSource implements OrdersDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  OrdersMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, Paged<OrderSummary>>> getOrders(OrdersQuery query) =>
      guardedRequest(
        'OrdersMockDataSource.getOrders',
        () async {
          await _backend.wait();
          return OrderSummaryModel.pageFrom(_backend.orders(await _language()));
        },
        fallbackMessage: 'order_failed',
      );

  @override
  Future<Either<Failure, OrderDetailModel>> getOrder(String id) =>
      guardedRequest(
        'OrdersMockDataSource.getOrder',
        () async {
          await _backend.wait();
          return OrderDetailModel.fromJson(
            _backend.order(id, await _language()),
          );
        },
        fallbackMessage: 'order_failed',
        messageForStatus: _orderMissing,
      );

  @override
  Future<Either<Failure, Unit>> rateOrder(RateOrderParams params) =>
      guardedRequest(
        'OrdersMockDataSource.rateOrder',
        () async {
          await _backend.wait();
          _backend.rateOrder(params.orderId, params.rating, await _language());
          return unit;
        },
        fallbackMessage: 'rating_failed',
        messageForStatus: _orderMissing,
      );
}
