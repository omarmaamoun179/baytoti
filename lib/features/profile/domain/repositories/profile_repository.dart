import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile();
}
