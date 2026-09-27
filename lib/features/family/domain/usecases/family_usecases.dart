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
  Future<Either<Failure, FamilyProfile>> call(String familyId) =>
      _repository.getFamily(familyId);
}

class FamilyProductsParams extends Equatable {
  final String familyId;
  final int? page;

  const FamilyProductsParams({required this.familyId, this.page});

  @override
  List<Object?> get props => [familyId, page];
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
      _repository.getProducts(params.familyId, page: params.page);
}

class SetFollowingParams extends Equatable {
  final String familyId;
  final bool following;

  const SetFollowingParams({required this.familyId, required this.following});

  @override
  List<Object?> get props => [familyId, following];
}

class SetFollowingUseCase
    implements UseCase<Either<Failure, bool>, SetFollowingParams> {
  final FamilyRepository _repository;

  SetFollowingUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(SetFollowingParams params) =>
      _repository.setFollowing(params.familyId, params.following);
}
