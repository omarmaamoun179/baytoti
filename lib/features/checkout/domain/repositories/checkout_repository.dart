import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/checkout.dart';

abstract class CheckoutRepository {
  Future<Either<Failure, CheckoutOptions>> getOptions();

  Future<Either<Failure, PlacedOrder>> placeOrder(PlaceOrderParams params);
}
