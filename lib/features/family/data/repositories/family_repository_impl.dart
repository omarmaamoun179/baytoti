import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../domain/entities/family_profile.dart';
import '../../domain/repositories/family_repository.dart';
import '../datasources/family_data_source.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  final FamilyDataSource _dataSource;

  FamilyRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, FamilyProfile>> getFamily(String slug) =>
      _dataSource.getFamily(slug);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String slug, {
    int? page,
  }) =>
      _dataSource.getProducts(slug, page: page);
}
