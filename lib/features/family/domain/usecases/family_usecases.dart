import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/domain/usecase.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../entities/family_profile.dart';
import '../repositories/family_repository.dart';

class GetFamilyUseCase
    implements UseCase<Either<Failure, FamilyProfile>, String> {
  final FamilyRepository _repository;

  GetFamilyUseCase(this._repository);

  @override
  Future<Either<Failure, FamilyProfile>> call(String slug) =>
      _repository.getFamily(slug);
}

class FamilyProductsParams extends Equatable {
  final String slug;
  final int? page;

  const FamilyProductsParams({required this.slug, this.page});

  @override
  List<Object?> get props => [slug, page];
}

class GetFamilyProductsUseCase
    implements
        UseCase<Either<Failure, Paged<ProductSummary>>, FamilyProductsParams> {
  final FamilyRepository _repository;

  GetFamilyProductsUseCase(this._repository);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> call(
    FamilyProductsParams params,
  ) =>
      _repository.getProducts(params.slug, page: params.page);
}
