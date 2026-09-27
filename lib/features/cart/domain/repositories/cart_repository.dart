import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/cart.dart';

abstract class CartRepository {
  Future<Either<Failure, Cart>> getCart();

  Future<Either<Failure, Cart>> addItem(String productId, int quantity);

  Future<Either<Failure, Cart>> updateItem(String itemId, int quantity);

  Future<Either<Failure, Cart>> removeItem(String itemId);
}
