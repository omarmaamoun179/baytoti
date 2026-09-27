import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../orders/data/models/order_models.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/checkout.dart';
import '../models/checkout_models.dart';

abstract class CheckoutDataSource {
  Future<Either<Failure, List<CheckoutAddress>>> getAddresses();

  Future<Either<Failure, List<OrderSummary>>> placeOrder(
    PlaceOrderParams params,
  );
}

class CheckoutRemoteDataSource implements CheckoutDataSource {
  final NetworkService _network;

  CheckoutRemoteDataSource(this._network);

  @override
  Future<Either<Failure, List<CheckoutAddress>>> getAddresses() =>
      guardedRequest(
        'CheckoutRemoteDataSource.getAddresses',
        () async {
          final response = await _network.get(ApiEndPoint.addresses);
          return CheckoutAddressModel.listFrom(
            checkedResponse(response).json['data'],
          );
        },
        fallbackMessage: 'checkout_failed',
      );

  @override
  Future<Either<Failure, List<OrderSummary>>> placeOrder(
    PlaceOrderParams params,
  ) =>
      guardedRequest(
        'CheckoutRemoteDataSource.placeOrder',
        () async {
          final response = await _network.post(
            ApiEndPoint.checkout,
            data: params.toJson(),
          );
          return OrderSummaryModel.listFromCheckout(checkedResponse(response));
        },
        fallbackMessage: 'order_place_failed',
      );
}
