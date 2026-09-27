import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../models/cart_model.dart';

abstract class CartDataSource {
  Future<Either<Failure, CartModel>> getCart();

  Future<Either<Failure, CartModel>> addItem(String productId, int quantity);

  Future<Either<Failure, CartModel>> updateItem(String itemId, int quantity);

  Future<Either<Failure, CartModel>> removeItem(String itemId);

  Future<Either<Failure, CartModel>> applyCoupon(String code);
}

class CartRemoteDataSource implements CartDataSource {
  final NetworkService _network;

  CartRemoteDataSource(this._network);

  Future<Either<Failure, CartModel>> _cart(
    String reason,
    Future<dynamic> Function() call, {
    String fallbackMessage = 'cart_update_failed',
  }) =>
      guardedRequest(
        'CartRemoteDataSource.$reason',
        () async => CartModel.fromJson(checkedResponse(await call()).json),
        fallbackMessage: fallbackMessage,
      );

  @override
  Future<Either<Failure, CartModel>> getCart() => _cart(
        'getCart',
        () => _network.get(ApiEndPoint.cart),
        fallbackMessage: 'cart_failed',
      );

  @override
  Future<Either<Failure, CartModel>> addItem(String productId, int quantity) =>
      _cart(
        'addItem',
        () => _network.post(
          ApiEndPoint.cartItems,
          data: {'product_id': productId, 'quantity': quantity},
        ),
      );

  @override
  Future<Either<Failure, CartModel>> updateItem(String itemId, int quantity) =>
      _cart(
        'updateItem',
        () => _network.patch(
          ApiEndPoint.cartItem(itemId),
          data: {'quantity': quantity},
        ),
      );

  @override
  Future<Either<Failure, CartModel>> removeItem(String itemId) => _cart(
        'removeItem',
        () => _network.delete(ApiEndPoint.cartItem(itemId)),
      );

  @override
  Future<Either<Failure, CartModel>> applyCoupon(String code) => _cart(
        'applyCoupon',
        () => _network.post(ApiEndPoint.cartCoupon, data: {'code': code}),
        fallbackMessage: 'coupon_failed',
      );
}

class CartMockDataSource implements CartDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  CartMockDataSource(this._backend, this._language);

  Future<Either<Failure, CartModel>> _cart(
    String reason,
    Map<String, dynamic> Function(String lang) call, {
    String fallbackMessage = 'cart_update_failed',
  }) =>
      guardedRequest(
        'CartMockDataSource.$reason',
        () async {
          await _backend.wait();
          return CartModel.fromJson(call(await _language()));
        },
        fallbackMessage: fallbackMessage,
      );

  @override
  Future<Either<Failure, CartModel>> getCart() =>
      _cart('getCart', _backend.cart, fallbackMessage: 'cart_failed');

  @override
  Future<Either<Failure, CartModel>> addItem(String productId, int quantity) =>
      _cart('addItem', (lang) => _backend.addToCart(productId, quantity, lang));

  @override
  Future<Either<Failure, CartModel>> updateItem(String itemId, int quantity) =>
      _cart(
        'updateItem',
        (lang) => _backend.updateCartItem(itemId, quantity, lang),
      );

  @override
  Future<Either<Failure, CartModel>> removeItem(String itemId) =>
      _cart('removeItem', (lang) => _backend.removeCartItem(itemId, lang));

  @override
  Future<Either<Failure, CartModel>> applyCoupon(String code) => _cart(
        'applyCoupon',
        (lang) => _backend.applyCoupon(code, lang),
        fallbackMessage: 'coupon_failed',
      );
}
