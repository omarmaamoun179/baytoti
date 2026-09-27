import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_data_source.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutDataSource _dataSource;

  CheckoutRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, CheckoutOptions>> getOptions() =>
      _dataSource.getOptions();

  @override
  Future<Either<Failure, PlacedOrder>> placeOrder(PlaceOrderParams params) =>
      _dataSource.placeOrder(params);
}
