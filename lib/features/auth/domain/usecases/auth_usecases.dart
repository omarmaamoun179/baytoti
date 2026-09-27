import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/customer.dart';
import '../entities/otp_challenge.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase
    implements UseCase<Either<Failure, AuthOutcome>, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, AuthOutcome>> call(RegisterParams params) =>
      _repository.register(params);
}

class LoginUseCase
    implements UseCase<Either<Failure, AuthOutcome>, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, AuthOutcome>> call(LoginParams params) =>
      _repository.login(params);
}

class RequestOtpUseCase
    implements UseCase<Either<Failure, OtpChallenge>, RequestOtpParams> {
  final AuthRepository _repository;

  RequestOtpUseCase(this._repository);

  @override
  Future<Either<Failure, OtpChallenge>> call(RequestOtpParams params) =>
      _repository.requestOtp(params);
}

class ResendOtpUseCase
    implements UseCase<Either<Failure, OtpChallenge>, OtpChallenge> {
  final AuthRepository _repository;

  ResendOtpUseCase(this._repository);

  @override
  Future<Either<Failure, OtpChallenge>> call(OtpChallenge challenge) =>
      _repository.resendOtp(challenge);
}

class VerifyOtpUseCase
    implements UseCase<Either<Failure, AuthSession>, VerifyOtpParams> {
  final AuthRepository _repository;

  VerifyOtpUseCase(this._repository);

  @override
  Future<Either<Failure, AuthSession>> call(VerifyOtpParams params) =>
      _repository.verifyOtp(params);
}

class RestoreSessionUseCase
    implements UseCase<Either<Failure, Customer?>, NoParams> {
  final AuthRepository _repository;

  RestoreSessionUseCase(this._repository);

  @override
  Future<Either<Failure, Customer?>> call(NoParams params) =>
      _repository.restoreSession();
}

class SignOutUseCase implements UseCase<Either<Failure, Unit>, NoParams> {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.signOut();
}

class ClearSessionUseCase implements UseCase<Either<Failure, Unit>, NoParams> {
  final AuthRepository _repository;

  ClearSessionUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.clearSession();
}
