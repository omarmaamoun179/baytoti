import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../auth/domain/entities/customer.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Customer>> getProfile();
}
