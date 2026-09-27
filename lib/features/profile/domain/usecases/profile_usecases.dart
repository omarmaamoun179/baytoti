import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase implements UseCase<Either<Failure, Profile>, NoParams> {
  final ProfileRepository _repository;

  GetProfileUseCase(this._repository);

  @override
  Future<Either<Failure, Profile>> call(NoParams params) =>
      _repository.getProfile();
}
