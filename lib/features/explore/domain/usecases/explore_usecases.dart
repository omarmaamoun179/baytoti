import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/explore_feed.dart';
import '../repositories/explore_repository.dart';

class ExploreParams extends Equatable {
  final ExploreTab tab;
  final int? page;

  const ExploreParams({required this.tab, this.page});

  @override
  List<Object?> get props => [tab, page];
}

class GetExploreUseCase
    implements UseCase<Either<Failure, ExploreFeed>, ExploreParams> {
  final ExploreRepository _repository;

  GetExploreUseCase(this._repository);

  @override
  Future<Either<Failure, ExploreFeed>> call(ExploreParams params) =>
      _repository.getExplore(params.tab, page: params.page);
}
