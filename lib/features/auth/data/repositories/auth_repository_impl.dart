import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _remote;
  final AuthLocalDataSource _local;

  AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, OtpChallenge>> requestOtp(RequestOtpParams params) =>
      _remote.requestOtp(params);

  @override
  Future<Either<Failure, OtpChallenge>> resendOtp(OtpChallenge challenge) =>
      _remote.resendOtp(challenge);

  @override
  Future<Either<Failure, AuthSession>> verifyOtp(VerifyOtpParams params) async {
    final result = await _remote.verifyOtp(params);

    return result.fold<Future<Either<Failure, AuthSession>>>(
      (failure) async => Left(failure),
      (payload) async {
        final saved = await _local.saveSession(payload.tokens, payload.customer);
        return saved.map(
          (_) => AuthSession(
            customer: payload.customer,
            isNewUser: payload.isNewUser,
          ),
        );
      },
    );
  }

  @override
  Future<Either<Failure, Customer?>> restoreSession() => _local.readSession();

  @override
  Future<Either<Failure, Unit>> signOut() async {
    await _remote.logout();
    return _local.clearSession();
  }

  @override
  Future<Either<Failure, Unit>> clearSession() => _local.clearSession();
}
