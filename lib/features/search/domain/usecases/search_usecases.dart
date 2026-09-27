import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/domain/usecase.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../entities/search_query.dart';
import '../repositories/search_repository.dart';

class SearchProductsUseCase
    implements UseCase<Either<Failure, Paged<ProductSummary>>, SearchQuery> {
  final SearchRepository _repository;

  SearchProductsUseCase(this._repository);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> call(SearchQuery query) =>
      _repository.search(query);
}

class GetSearchCategoriesUseCase
    implements UseCase<Either<Failure, List<Category>>, NoParams> {
  final SearchRepository _repository;

  GetSearchCategoriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) =>
      _repository.getCategories();
}
