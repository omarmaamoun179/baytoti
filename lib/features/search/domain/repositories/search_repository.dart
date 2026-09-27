import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../entities/search_query.dart';

abstract class SearchRepository {
  Future<Either<Failure, Paged<ProductSummary>>> search(SearchQuery query);

  Future<Either<Failure, List<Category>>> getCategories();
}
