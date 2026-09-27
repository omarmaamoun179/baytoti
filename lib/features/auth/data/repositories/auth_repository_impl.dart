import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/failure_mapper.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _remote;
  final AuthLocalDataSource _local;
  AuthAccountPayload? _pending;

  AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, AuthOutcome>> register(RegisterParams params) async {
    final result = await _remote.register(params);
    return result.fold(
      (failure) async => Left(failure),
      (payload) => _settle(payload, fallbackPhone: params.phone),
    );
  }

  @override
  Future<Either<Failure, AuthOutcome>> login(LoginParams params) async {
    final result = await _remote.login(params);
    return result.fold(
      (failure) async => Left(failure),
      (payload) => _settle(payload, fallbackPhone: params.phone),
    );
  }

  Future<Either<Failure, AuthOutcome>> _settle(
    AuthAccountPayload payload, {
    required String fallbackPhone,
  }) async {
    final token = payload.token;
    final customer = payload.customer;

    if (token == null || token.isEmpty || !customer.verified) {
      _pending = payload;
      return Right(AwaitingVerification(
        customer.phone.isEmpty ? fallbackPhone : customer.phone,
      ));
    }

    _pending = null;
    final saved = await _local.saveSession(
      TokenPair(accessToken: token),
      customer,
    );
    return saved.map((_) => SignedIn(customer));
  }

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
        final token = payload.token ?? _pending?.token;
        final customer = payload.customer ?? _pending?.customer;
        if (token == null || token.isEmpty || customer == null) {
          return Left(mapExceptionToFailure(
            const RequestException('auth_failed'),
          ));
        }

        final verified = customer.verifiedCopy();
        final saved = await _local.saveSession(
          TokenPair(accessToken: token, refreshToken: payload.refreshToken),
          verified,
        );
        return saved.map((_) {
          _pending = null;
          return AuthSession(customer: verified, isNewUser: payload.isNewUser);
        });
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
