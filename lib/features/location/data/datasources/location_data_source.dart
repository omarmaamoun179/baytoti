import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/network_service.dart';
import '../../domain/entities/location.dart';
import '../models/location_models.dart';

abstract class LocationDataSource {
  Future<Either<Failure, List<Country>>> getCountries();

  Future<Either<Failure, List<Governorate>>> getGovernorates(String countryId);

  Future<Either<Failure, LocationContext>> getContext();

  Future<Either<Failure, LocationContext>> setManual({
    required String countryId,
    required String governorateId,
  });
}

class LocationRemoteDataSource implements LocationDataSource {
  final NetworkService _network;

  LocationRemoteDataSource(this._network);

  @override
  Future<Either<Failure, List<Country>>> getCountries() => guardedRequest(
        'LocationRemoteDataSource.getCountries',
        () async {
          final response = await _network.get(
            ApiEndPoint.countries,
            skipAuthRefresh: true,
          );
          return CountryModel.listFrom(checkedResponse(response).json['data']);
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates(
    String countryId,
  ) =>
      guardedRequest(
        'LocationRemoteDataSource.getGovernorates',
        () async {
          final response = await _network.get(
            ApiEndPoint.countryGovernorates(countryId),
            skipAuthRefresh: true,
          );
          return GovernorateModel.listFrom(
            checkedResponse(response).json['data'],
          );
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, LocationContext>> getContext() => guardedRequest(
        'LocationRemoteDataSource.getContext',
        () async {
          final response = await _network.get(ApiEndPoint.locationContext);
          try {
            return LocationContextModel.fromJson(
              checkedResponse(response).json,
            );
          } on RequestException catch (e) {
            if (e.statusCode == 404) return LocationContext.none;
            rethrow;
          }
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, LocationContext>> setManual({
    required String countryId,
    required String governorateId,
  }) =>
      guardedRequest(
        'LocationRemoteDataSource.setManual',
        () async {
          final response = await _network.post(
            ApiEndPoint.locationContext,
            data: {
              'mode': 'manual',
              'country_id': int.tryParse(countryId) ?? countryId,
              'governorate_id': int.tryParse(governorateId) ?? governorateId,
            },
          );
          return LocationContextModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'location_failed',
      );
}

abstract class LocationLocalDataSource {
  Future<Either<Failure, LocationContext>> read();

  Future<Either<Failure, Unit>> save(LocationContext context);

  Future<Either<Failure, Unit>> clear();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  final CacheService _cache;

  LocationLocalDataSourceImpl(this._cache);

  @override
  Future<Either<Failure, LocationContext>> read() => guardedStorage(
        'LocationLocalDataSource.read',
        () async {
          final stored = await _cache.getUserLocation();
          if (stored == null || stored.isEmpty) return LocationContext.none;
          return LocationContextModel.decode(stored);
        },
      );

  @override
  Future<Either<Failure, Unit>> save(LocationContext context) => guardedStorage(
        'LocationLocalDataSource.save',
        () async {
          await _cache.saveUserLocation(LocationContextModel.encode(context));
          return unit;
        },
      );

  @override
  Future<Either<Failure, Unit>> clear() => guardedStorage(
        'LocationLocalDataSource.clear',
        () async {
          await _cache.clearUserLocation();
          return unit;
        },
      );
}
