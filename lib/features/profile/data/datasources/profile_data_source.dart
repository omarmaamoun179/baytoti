import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../models/profile_model.dart';

abstract class ProfileDataSource {
  Future<Either<Failure, ProfileModel>> getProfile();
}

class ProfileRemoteDataSource implements ProfileDataSource {
  final NetworkService _network;

  ProfileRemoteDataSource(this._network);

  @override
  Future<Either<Failure, ProfileModel>> getProfile() => guardedRequest(
        'ProfileRemoteDataSource.getProfile',
        () async => ProfileModel.fromJson(
          checkedResponse(await _network.get(ApiEndPoint.me)).json,
        ),
        fallbackMessage: 'profile_failed',
      );
}

class ProfileMockDataSource implements ProfileDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  ProfileMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, ProfileModel>> getProfile() => guardedRequest(
        'ProfileMockDataSource.getProfile',
        () async {
          await _backend.wait();
          return ProfileModel.fromJson(_backend.me(await _language()));
        },
        fallbackMessage: 'profile_failed',
      );
}
