import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../fixtures/fixture_backend.dart';

abstract class FavouritesDataSource {
  Future<Either<Failure, bool>> setFavourite(String productId, bool favourite);
}

class FavouritesRemoteDataSource implements FavouritesDataSource {
  final NetworkService _network;

  FavouritesRemoteDataSource(this._network);

  @override
  Future<Either<Failure, bool>> setFavourite(
    String productId,
    bool favourite,
  ) =>
      guardedRequest(
        'FavouritesRemoteDataSource.setFavourite',
        () async {
          final response = favourite
              ? await _network.post(
                  ApiEndPoint.favourites,
                  data: {'product_id': productId},
                )
              : await _network.delete(ApiEndPoint.favourite(productId));
          final json = checkedResponse(response).json;
          return json['is_favourite'] as bool? ?? favourite;
        },
        fallbackMessage: 'favourite_failed',
      );
}

class FavouritesMockDataSource implements FavouritesDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  FavouritesMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, bool>> setFavourite(
    String productId,
    bool favourite,
  ) =>
      guardedRequest(
        'FavouritesMockDataSource.setFavourite',
        () async {
          await _backend.wait();
          final json = _backend.setFavourite(
            productId,
            favourite: favourite,
            lang: await _language(),
          );
          return json['is_favourite'] as bool;
        },
        fallbackMessage: 'favourite_failed',
      );
}
