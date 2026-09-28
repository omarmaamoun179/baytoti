import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../auth/domain/entities/customer.dart';
import '../entities/profile_update.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Customer>> getProfile();

  Future<Either<Failure, Customer>> updateProfile(ProfileUpdate update);
}
