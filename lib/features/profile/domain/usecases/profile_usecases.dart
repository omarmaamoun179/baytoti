import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../../../auth/domain/entities/customer.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase
    implements UseCase<Either<Failure, Customer>, NoParams> {
  final ProfileRepository _repository;

  GetProfileUseCase(this._repository);

  @override
  Future<Either<Failure, Customer>> call(NoParams params) =>
      _repository.getProfile();
}
