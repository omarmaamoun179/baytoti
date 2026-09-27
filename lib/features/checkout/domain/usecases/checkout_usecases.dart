import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class GetCheckoutOptionsUseCase
    implements UseCase<Either<Failure, CheckoutOptions>, NoParams> {
  final CheckoutRepository _repository;

  GetCheckoutOptionsUseCase(this._repository);

  @override
  Future<Either<Failure, CheckoutOptions>> call(NoParams params) =>
      _repository.getOptions();
}

class PlaceOrderUseCase
    implements UseCase<Either<Failure, PlacedOrder>, PlaceOrderParams> {
  final CheckoutRepository _repository;

  PlaceOrderUseCase(this._repository);

  @override
  Future<Either<Failure, PlacedOrder>> call(PlaceOrderParams params) =>
      _repository.placeOrder(params);
}
