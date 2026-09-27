import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/domain/usecase.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../entities/explore_tab.dart';
import '../repositories/explore_repository.dart';

class ExploreParams extends Equatable {
  final ExploreTab tab;
  final int page;

  const ExploreParams({required this.tab, this.page = 1});

  @override
  List<Object?> get props => [tab, page];
}

class GetExploreUseCase
    implements UseCase<Either<Failure, Paged<ProductSummary>>, ExploreParams> {
  final ExploreRepository _repository;

  GetExploreUseCase(this._repository);

  @override
  Future<Either<Failure, Paged<ProductSummary>>> call(ExploreParams params) =>
      _repository.getProducts(params.tab, page: params.page);
}
