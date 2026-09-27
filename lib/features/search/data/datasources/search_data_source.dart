import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../../domain/entities/search_query.dart';
import '../models/search_model.dart';

abstract class SearchDataSource {
  Future<Either<Failure, SearchResultsModel>> search(SearchQuery query);
}

class SearchRemoteDataSource implements SearchDataSource {
  final NetworkService _network;

  SearchRemoteDataSource(this._network);

  @override
  Future<Either<Failure, SearchResultsModel>> search(SearchQuery query) =>
      guardedRequest(
        'SearchRemoteDataSource.search',
        () async {
          final response = await _network.get(
            ApiEndPoint.search,
            queryParameters: query.toQueryParameters(),
          );
          return SearchResultsModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'search_failed',
      );
}

class SearchMockDataSource implements SearchDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  SearchMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, SearchResultsModel>> search(SearchQuery query) =>
      guardedRequest(
        'SearchMockDataSource.search',
        () async {
          await _backend.wait();
          return SearchResultsModel.fromJson(
            _backend.search(
              lang: await _language(),
              query: query.text.isEmpty ? null : query.text,
              categoryId: query.categoryId,
              city: query.city,
              minRating: query.minRating,
              sort: query.sort.wire,
            ),
          );
        },
        fallbackMessage: 'search_failed',
      );
}
