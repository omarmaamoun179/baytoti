import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/home_feed.dart';
import '../models/home_feed_model.dart';

abstract class HomeDataSource {
  Future<Either<Failure, HomeFeedModel>> getHome();

  Future<Either<Failure, List<TrustedStore>>> getStores();
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

  @override
  Future<Either<Failure, List<TrustedStore>>> getStores() => guardedRequest(
        'HomeRemoteDataSource.getStores',
        () async {
          final response = await _network.get(ApiEndPoint.stores);
          final json = checkedResponse(response).json;
          if (json['data'] is! List) {
            throw const FormatException('the stores answer has no list');
          }
          return [
            for (final item in jsonList(json['data']))
              TrustedStoreModel.fromJson(item),
          ];
        },
        fallbackMessage: 'stores_failed',
      );
}
