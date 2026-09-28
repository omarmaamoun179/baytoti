import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../../../auth/domain/entities/customer.dart';
import '../entities/profile_update.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase
    implements UseCase<Either<Failure, Customer>, NoParams> {
  final ProfileRepository _repository;

  GetProfileUseCase(this._repository);

  @override
  Future<Either<Failure, Customer>> call(NoParams params) =>
      _repository.getProfile();
}

class UpdateProfileUseCase
    implements UseCase<Either<Failure, Customer>, ProfileUpdate> {
  final ProfileRepository _repository;

  UpdateProfileUseCase(this._repository);

  @override
  Future<Either<Failure, Customer>> call(ProfileUpdate update) =>
      _repository.updateProfile(update);
}
