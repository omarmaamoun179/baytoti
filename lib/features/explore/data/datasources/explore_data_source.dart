import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../../domain/entities/explore_feed.dart';
import '../models/explore_model.dart';

abstract class ExploreDataSource {
  Future<Either<Failure, ExploreFeedModel>> getExplore(
    ExploreTab tab, {
    int? page,
  });
}

class ExploreRemoteDataSource implements ExploreDataSource {
  final NetworkService _network;

  ExploreRemoteDataSource(this._network);

  @override
  Future<Either<Failure, ExploreFeedModel>> getExplore(
    ExploreTab tab, {
    int? page,
  }) =>
      guardedRequest(
        'ExploreRemoteDataSource.getExplore',
        () async {
          final response = await _network.get(
            ApiEndPoint.explore,
            queryParameters: {'tab': tab.wire, 'page': ?page},
          );
          return ExploreFeedModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'explore_failed',
      );
}

class ExploreMockDataSource implements ExploreDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  ExploreMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, ExploreFeedModel>> getExplore(
    ExploreTab tab, {
    int? page,
  }) =>
      guardedRequest(
        'ExploreMockDataSource.getExplore',
        () async {
          await _backend.wait();
          return ExploreFeedModel.fromJson(
            _backend.explore(tab.wire, await _language()),
          );
        },
        fallbackMessage: 'explore_failed',
      );
}
