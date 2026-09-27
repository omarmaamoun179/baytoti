import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/addresses_repository.dart';
import '../datasources/addresses_data_source.dart';

class AddressesRepositoryImpl implements AddressesRepository {
  final AddressesDataSource _dataSource;

  AddressesRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Address>>> getAddresses() =>
      _dataSource.getAddresses();

  @override
  Future<Either<Failure, Address>> create(AddressParams params) =>
      _dataSource.create(params);

  @override
  Future<Either<Failure, Address>> update(String id, AddressParams params) =>
      _dataSource.update(id, params);

  @override
  Future<Either<Failure, Unit>> delete(String id) => _dataSource.delete(id);

  @override
  Future<Either<Failure, Unit>> setDefault(String id) =>
      _dataSource.setDefault(id);
}
