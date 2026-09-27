import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../models/home_feed_model.dart';

abstract class HomeDataSource {
  Future<Either<Failure, HomeFeedModel>> getHome();
}

class HomeRemoteDataSource implements HomeDataSource {
  final NetworkService _network;

  HomeRemoteDataSource(this._network);

  @override
  Future<Either<Failure, HomeFeedModel>> getHome() => guardedRequest(
        'HomeRemoteDataSource.getHome',
        () async {
          final response = await _network.get(ApiEndPoint.home);
          return HomeFeedModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'home_failed',
      );
}

class HomeMockDataSource implements HomeDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  HomeMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, HomeFeedModel>> getHome() => guardedRequest(
        'HomeMockDataSource.getHome',
        () async {
          await _backend.wait();
          return HomeFeedModel.fromJson(_backend.home(await _language()));
        },
        fallbackMessage: 'home_failed',
      );
}
