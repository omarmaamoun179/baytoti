import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchDataSource _dataSource;

  SearchRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> search(SearchQuery query) =>
      _dataSource.search(query);

  @override
  Future<Either<Failure, List<Category>>> getCategories() =>
      _dataSource.getCategories();
}
