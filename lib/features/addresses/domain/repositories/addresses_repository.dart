import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/address.dart';

abstract class AddressesRepository {
  Future<Either<Failure, List<Address>>> getAddresses();

  Future<Either<Failure, Address>> create(AddressParams params);

  Future<Either<Failure, Address>> update(String id, AddressParams params);

  Future<Either<Failure, Unit>> delete(String id);

  Future<Either<Failure, Unit>> setDefault(String id);
}
