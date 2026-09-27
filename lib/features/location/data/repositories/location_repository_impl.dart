import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _remote;
  final LocationLocalDataSource _local;

  LocationRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, List<Country>>> getCountries() =>
      _remote.getCountries();

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates(
    String countryId,
  ) =>
      _remote.getGovernorates(countryId);

  @override
  Future<Either<Failure, LocationContext>> getContext() async {
    final remote = await _remote.getContext();

    return remote.fold<Future<Either<Failure, LocationContext>>>(
      (failure) async => Left(failure),
      (context) async {
        if (!context.isSet || context.countryCode != null) {
          return Right(context);
        }
        final stored = await _local.read();
        final code = stored.fold(
          (_) => null,
          (local) =>
              local.countryId == context.countryId ? local.countryCode : null,
        );
        return Right(context.withCode(code));
      },
    );
  }

  @override
  Future<Either<Failure, LocationContext>> setManual({
    required Country country,
    required Governorate governorate,
  }) async {
    final result = await _remote.setManual(
      countryId: country.id,
      governorateId: governorate.id,
    );

    return result.fold<Future<Either<Failure, LocationContext>>>(
      (failure) async => Left(failure),
      (answered) async {
        final context = (answered.isSet
                ? answered
                : LocationContext(
                    countryId: country.id,
                    governorateId: governorate.id,
                  ))
            .withCode(country.code);
        final saved = await _local.save(context);
        return saved.map((_) => context);
      },
    );
  }

  @override
  Future<Either<Failure, LocationContext>> cached() => _local.read();

  @override
  Future<Either<Failure, Unit>> forget() => _local.clear();
}
