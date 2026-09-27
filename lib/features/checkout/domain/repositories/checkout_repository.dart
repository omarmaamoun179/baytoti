import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../orders/domain/entities/order.dart';
import '../entities/checkout.dart';

abstract class CheckoutRepository {
  Future<Either<Failure, List<CheckoutAddress>>> getAddresses();

  Future<Either<Failure, List<OrderSummary>>> placeOrder(
    PlaceOrderParams params,
  );
}
