import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class GetCartUseCase implements UseCase<Either<Failure, Cart>, NoParams> {
  final CartRepository _repository;

  GetCartUseCase(this._repository);

  @override
  Future<Either<Failure, Cart>> call(NoParams params) => _repository.getCart();
}

class CartQuantityParams extends Equatable {
  final String id;
  final int quantity;

  const CartQuantityParams({required this.id, required this.quantity});

  @override
  List<Object?> get props => [id, quantity];
}

class AddToCartUseCase
    implements UseCase<Either<Failure, Cart>, CartQuantityParams> {
  final CartRepository _repository;

  AddToCartUseCase(this._repository);

  @override
  Future<Either<Failure, Cart>> call(CartQuantityParams params) =>
      _repository.addItem(params.id, params.quantity);
}

class UpdateCartItemUseCase
    implements UseCase<Either<Failure, Cart>, CartQuantityParams> {
  final CartRepository _repository;

  UpdateCartItemUseCase(this._repository);

  @override
  Future<Either<Failure, Cart>> call(CartQuantityParams params) =>
      _repository.updateItem(params.id, params.quantity);
}

class RemoveCartItemUseCase implements UseCase<Either<Failure, Cart>, String> {
  final CartRepository _repository;

  RemoveCartItemUseCase(this._repository);

  @override
  Future<Either<Failure, Cart>> call(String itemId) =>
      _repository.removeItem(itemId);
}
