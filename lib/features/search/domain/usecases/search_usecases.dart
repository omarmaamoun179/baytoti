import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/search_query.dart';
import '../entities/search_results.dart';
import '../repositories/search_repository.dart';

class SearchProductsUseCase
    implements UseCase<Either<Failure, SearchResults>, SearchQuery> {
  final SearchRepository _repository;

  SearchProductsUseCase(this._repository);

  @override
  Future<Either<Failure, SearchResults>> call(SearchQuery query) =>
      _repository.search(query);
}
