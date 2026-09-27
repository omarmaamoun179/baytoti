import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  final CartDataSource _dataSource;

  CartRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Cart>> getCart() => _dataSource.getCart();

  @override
  Future<Either<Failure, Cart>> addItem(String productId, int quantity) =>
      _dataSource.addItem(productId, quantity);

  @override
  Future<Either<Failure, Cart>> updateItem(String itemId, int quantity) =>
      _dataSource.updateItem(itemId, quantity);

  @override
  Future<Either<Failure, Cart>> removeItem(String itemId) =>
      _dataSource.removeItem(itemId);
}
