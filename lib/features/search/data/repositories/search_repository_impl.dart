import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/search_results.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchDataSource _dataSource;

  SearchRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, SearchResults>> search(SearchQuery query) =>
      _dataSource.search(query);
}
