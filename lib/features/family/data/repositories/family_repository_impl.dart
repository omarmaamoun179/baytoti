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
  Future<Either<Failure, FamilyProfile>> getFamily(String familyId) =>
      _dataSource.getFamily(familyId);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String familyId, {
    String? cursor,
  }) =>
      _dataSource.getProducts(familyId, cursor: cursor);

  @override
  Future<Either<Failure, bool>> setFollowing(String familyId, bool following) =>
      _dataSource.setFollowing(familyId, following);
}
