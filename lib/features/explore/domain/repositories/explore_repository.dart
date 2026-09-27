import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../entities/explore_tab.dart';

abstract class ExploreRepository {
  Future<Either<Failure, Paged<ProductSummary>>> getProducts(
    ExploreTab tab, {
    int page = 1,
  });
}
