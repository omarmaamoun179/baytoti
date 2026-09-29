import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/product_detail.dart';

abstract class ProductRepository {
  Future<Either<Failure, ProductDetail>> getProduct(String slug);

  Future<Either<Failure, ReviewDigest>> getReviews(ReviewsQuery query);
}
