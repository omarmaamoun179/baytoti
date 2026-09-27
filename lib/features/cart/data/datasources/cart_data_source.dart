import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' show Response;

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../models/cart_model.dart';

abstract class CartDataSource {
  Future<Either<Failure, CartModel>> getCart();

  Future<Either<Failure, CartModel>> addItem(String productId, int quantity);

  Future<Either<Failure, CartModel>> updateItem(String itemId, int quantity);

  Future<Either<Failure, CartModel>> removeItem(String itemId);
}

class CartRemoteDataSource implements CartDataSource {
  static const Map<int, String> _lineMissing = {404: 'cart_update_failed'};

  final NetworkService _network;

  CartRemoteDataSource(this._network);

  Future<CartModel> _read() async => CartModel.fromResponse(
        checkedResponse(await _network.get(ApiEndPoint.cart)),
      );

  Future<Either<Failure, CartModel>> _mutate(
    String reason,
    Future<Response<dynamic>> Function() call,
  ) =>
      guardedRequest(
        'CartRemoteDataSource.$reason',
        () async {
          final response = checkedResponse(await call());
          if (CartModel.carriesCart(response)) {
            return CartModel.fromResponse(response);
          }
          return _read();
        },
        fallbackMessage: 'cart_update_failed',
        messageForStatus: _lineMissing,
      );

  @override
  Future<Either<Failure, CartModel>> getCart() => guardedRequest(
        'CartRemoteDataSource.getCart',
        _read,
        fallbackMessage: 'cart_failed',
      );

  @override
  Future<Either<Failure, CartModel>> addItem(String productId, int quantity) =>
      _mutate(
        'addItem',
        () => _network.post(
          ApiEndPoint.cartItems,
          data: {
            'product_id': int.tryParse(productId) ?? productId,
            'quantity': quantity,
          },
        ),
      );

  @override
  Future<Either<Failure, CartModel>> updateItem(String itemId, int quantity) =>
      _mutate(
        'updateItem',
        () => _network.patch(
          ApiEndPoint.cartItem(itemId),
          data: {'quantity': quantity},
        ),
      );

  @override
  Future<Either<Failure, CartModel>> removeItem(String itemId) => _mutate(
        'removeItem',
        () => _network.delete(ApiEndPoint.cartItem(itemId)),
      );
}
