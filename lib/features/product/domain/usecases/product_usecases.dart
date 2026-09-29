import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/product_detail.dart';
import '../repositories/product_repository.dart';

class GetProductUseCase
    implements UseCase<Either<Failure, ProductDetail>, String> {
  final ProductRepository _repository;

  GetProductUseCase(this._repository);

  @override
  Future<Either<Failure, ProductDetail>> call(String slug) =>
      _repository.getProduct(slug);
}

class GetProductReviewsUseCase
    implements UseCase<Either<Failure, ReviewDigest>, ReviewsQuery> {
  final ProductRepository _repository;

  GetProductReviewsUseCase(this._repository);

  @override
  Future<Either<Failure, ReviewDigest>> call(ReviewsQuery query) =>
      _repository.getReviews(query);
}
