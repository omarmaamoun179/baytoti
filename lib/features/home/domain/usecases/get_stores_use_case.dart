import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/home_feed.dart';
import '../repositories/home_repository.dart';

class GetStoresUseCase
    implements UseCase<Either<Failure, List<TrustedStore>>, NoParams> {
  final HomeRepository _repository;

  GetStoresUseCase(this._repository);

  @override
  Future<Either<Failure, List<TrustedStore>>> call(NoParams params) =>
      _repository.getStores();
}
