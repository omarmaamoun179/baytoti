import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/explore_feed.dart';
import '../repositories/explore_repository.dart';

class ExploreParams extends Equatable {
  final ExploreTab tab;
  final String? cursor;

  const ExploreParams({required this.tab, this.cursor});

  @override
  List<Object?> get props => [tab, cursor];
}

class GetExploreUseCase
    implements UseCase<Either<Failure, ExploreFeed>, ExploreParams> {
  final ExploreRepository _repository;

  GetExploreUseCase(this._repository);

  @override
  Future<Either<Failure, ExploreFeed>> call(ExploreParams params) =>
      _repository.getExplore(params.tab, cursor: params.cursor);
}
