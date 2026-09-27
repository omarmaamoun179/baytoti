import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/customer.dart';
import '../entities/otp_challenge.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthOutcome>> register(RegisterParams params);

  Future<Either<Failure, AuthOutcome>> login(LoginParams params);

  Future<Either<Failure, OtpChallenge>> requestOtp(RequestOtpParams params);

  Future<Either<Failure, OtpChallenge>> resendOtp(OtpChallenge challenge);

  Future<Either<Failure, AuthSession>> verifyOtp(VerifyOtpParams params);

  Future<Either<Failure, Customer?>> restoreSession();

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, Unit>> clearSession();
}
