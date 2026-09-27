import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../../domain/entities/checkout.dart';
import '../models/checkout_models.dart';

const String idempotencyHeader = 'Idempotency-Key';

abstract class CheckoutDataSource {
  Future<Either<Failure, CheckoutOptionsModel>> getOptions();

  Future<Either<Failure, PlacedOrderModel>> placeOrder(
    PlaceOrderParams params,
  );
}

class CheckoutRemoteDataSource implements CheckoutDataSource {
  final NetworkService _network;

  CheckoutRemoteDataSource(this._network);

  @override
  Future<Either<Failure, CheckoutOptionsModel>> getOptions() => guardedRequest(
        'CheckoutRemoteDataSource.getOptions',
        () async {
          final response = await _network.get(ApiEndPoint.checkoutOptions);
          return CheckoutOptionsModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'checkout_failed',
      );

  @override
  Future<Either<Failure, PlacedOrderModel>> placeOrder(
    PlaceOrderParams params,
  ) =>
      guardedRequest(
        'CheckoutRemoteDataSource.placeOrder',
        () async {
          final response = await _network.post(
            ApiEndPoint.orders,
            data: params.toJson(),
            headers: {
              ...await _network.getDefaultHeaders(),
              idempotencyHeader: params.idempotencyKey,
            },
          );
          return PlacedOrderModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'order_place_failed',
      );
}

class CheckoutMockDataSource implements CheckoutDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  CheckoutMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, CheckoutOptionsModel>> getOptions() => guardedRequest(
        'CheckoutMockDataSource.getOptions',
        () async {
          await _backend.wait();
          return CheckoutOptionsModel.fromJson(
            _backend.checkoutOptions(await _language()),
          );
        },
        fallbackMessage: 'checkout_failed',
      );

  @override
  Future<Either<Failure, PlacedOrderModel>> placeOrder(
    PlaceOrderParams params,
  ) =>
      guardedRequest(
        'CheckoutMockDataSource.placeOrder',
        () async {
          await _backend.wait();
          return PlacedOrderModel.fromJson(_backend.placeOrder(
            fulfilment: params.fulfilmentMethod,
            lang: await _language(),
          ));
        },
        fallbackMessage: 'order_place_failed',
      );
}
