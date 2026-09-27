import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../entities/family_profile.dart';

abstract class FamilyRepository {
  Future<Either<Failure, FamilyProfile>> getFamily(String slug);

  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    String slug, {
    int? page,
  });
}
