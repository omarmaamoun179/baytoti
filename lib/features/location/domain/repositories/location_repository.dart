import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/location.dart';

abstract class LocationRepository {
  Future<Either<Failure, List<Country>>> getCountries();

  Future<Either<Failure, List<Governorate>>> getGovernorates(String countryId);

  Future<Either<Failure, LocationContext>> getContext();

  Future<Either<Failure, LocationContext>> cached();

  Future<Either<Failure, LocationContext>> setManual({
    required Country country,
    required Governorate governorate,
  });

  Future<Either<Failure, Unit>> forget();
}
