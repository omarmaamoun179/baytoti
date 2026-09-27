import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetCountriesUseCase
    implements UseCase<Either<Failure, List<Country>>, NoParams> {
  final LocationRepository _repository;

  GetCountriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Country>>> call(NoParams params) =>
      _repository.getCountries();
}

class GetGovernoratesUseCase
    implements UseCase<Either<Failure, List<Governorate>>, String> {
  final LocationRepository _repository;

  GetGovernoratesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Governorate>>> call(String countryId) =>
      _repository.getGovernorates(countryId);
}

class GetLocationContextUseCase
    implements UseCase<Either<Failure, LocationContext>, NoParams> {
  final LocationRepository _repository;

  GetLocationContextUseCase(this._repository);

  @override
  Future<Either<Failure, LocationContext>> call(NoParams params) =>
      _repository.getContext();
}

class GetCachedLocationUseCase
    implements UseCase<Either<Failure, LocationContext>, NoParams> {
  final LocationRepository _repository;

  GetCachedLocationUseCase(this._repository);

  @override
  Future<Either<Failure, LocationContext>> call(NoParams params) =>
      _repository.cached();
}

class ManualLocationParams extends Equatable {
  final Country country;
  final Governorate governorate;

  const ManualLocationParams({required this.country, required this.governorate});

  @override
  List<Object?> get props => [country, governorate];
}

class SetManualLocationUseCase
    implements UseCase<Either<Failure, LocationContext>, ManualLocationParams> {
  final LocationRepository _repository;

  SetManualLocationUseCase(this._repository);

  @override
  Future<Either<Failure, LocationContext>> call(ManualLocationParams params) =>
      _repository.setManual(
        country: params.country,
        governorate: params.governorate,
      );
}

class ForgetLocationUseCase implements UseCase<Either<Failure, Unit>, NoParams> {
  final LocationRepository _repository;

  ForgetLocationUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.forget();
}
