import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../../../orders/domain/entities/order.dart';
import '../entities/checkout.dart';
import '../repositories/checkout_repository.dart';

class GetCheckoutAddressesUseCase
    implements UseCase<Either<Failure, List<CheckoutAddress>>, NoParams> {
  final CheckoutRepository _repository;

  GetCheckoutAddressesUseCase(this._repository);

  @override
  Future<Either<Failure, List<CheckoutAddress>>> call(NoParams params) =>
      _repository.getAddresses();
}

class PlaceOrderUseCase
    implements UseCase<Either<Failure, List<OrderSummary>>, PlaceOrderParams> {
  final CheckoutRepository _repository;

  PlaceOrderUseCase(this._repository);

  @override
  Future<Either<Failure, List<OrderSummary>>> call(PlaceOrderParams params) =>
      _repository.placeOrder(params);
}
