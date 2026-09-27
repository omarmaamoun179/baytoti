import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/address.dart';
import '../repositories/addresses_repository.dart';

class GetAddressesUseCase
    implements UseCase<Either<Failure, List<Address>>, NoParams> {
  final AddressesRepository _repository;

  GetAddressesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Address>>> call(NoParams params) =>
      _repository.getAddresses();
}

class CreateAddressUseCase
    implements UseCase<Either<Failure, Address>, AddressParams> {
  final AddressesRepository _repository;

  CreateAddressUseCase(this._repository);

  @override
  Future<Either<Failure, Address>> call(AddressParams params) =>
      _repository.create(params);
}

class UpdateAddressParams extends Equatable {
  final String id;
  final AddressParams address;

  const UpdateAddressParams({required this.id, required this.address});

  @override
  List<Object?> get props => [id, address];
}

class UpdateAddressUseCase
    implements UseCase<Either<Failure, Address>, UpdateAddressParams> {
  final AddressesRepository _repository;

  UpdateAddressUseCase(this._repository);

  @override
  Future<Either<Failure, Address>> call(UpdateAddressParams params) =>
      _repository.update(params.id, params.address);
}

class DeleteAddressUseCase implements UseCase<Either<Failure, Unit>, String> {
  final AddressesRepository _repository;

  DeleteAddressUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String id) => _repository.delete(id);
}

class SetDefaultAddressUseCase
    implements UseCase<Either<Failure, Unit>, String> {
  final AddressesRepository _repository;

  SetDefaultAddressUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String id) => _repository.setDefault(id);
}
