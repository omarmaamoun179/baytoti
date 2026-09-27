import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/home_feed.dart';
import '../repositories/home_repository.dart';

class GetHomeUseCase implements UseCase<Either<Failure, HomeFeed>, NoParams> {
  final HomeRepository _repository;

  GetHomeUseCase(this._repository);

  @override
  Future<Either<Failure, HomeFeed>> call(NoParams params) =>
      _repository.getHome();
}
