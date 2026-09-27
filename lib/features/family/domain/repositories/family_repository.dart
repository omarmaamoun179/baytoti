import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../entities/family_profile.dart';

abstract class FamilyRepository {
  Future<Either<Failure, FamilyProfile>> getFamily(String familyId);

  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String familyId, {
    int? page,
  });

  Future<Either<Failure, bool>> setFollowing(String familyId, bool following);
}
