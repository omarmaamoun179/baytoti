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
  Future<Either<Failure, ProductDetail>> call(String productId) =>
      _repository.getProduct(productId);
}
