import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../auth/domain/entities/customer.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource _dataSource;

  ProfileRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Customer>> getProfile() => _dataSource.getProfile();

  @override
  Future<Either<Failure, Customer>> updateProfile(ProfileUpdate update) =>
      _dataSource.updateProfile(update);
}
