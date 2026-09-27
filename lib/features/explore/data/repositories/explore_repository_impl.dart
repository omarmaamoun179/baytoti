import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../domain/entities/explore_tab.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_data_source.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final ExploreDataSource _dataSource;

  ExploreRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    ExploreTab tab, {
    int page = 1,
  }) =>
      _dataSource.getProducts(tab, page: page);
}
