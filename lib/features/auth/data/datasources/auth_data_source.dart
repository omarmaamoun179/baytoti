import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../../domain/entities/otp_challenge.dart';
import '../models/auth_models.dart';

abstract class AuthDataSource {
  Future<Either<Failure, AuthAccountPayload>> register(RegisterParams params);

  Future<Either<Failure, AuthAccountPayload>> login(LoginParams params);

  Future<Either<Failure, OtpChallengeModel>> requestOtp(RequestOtpParams params);

  Future<Either<Failure, OtpChallengeModel>> resendOtp(OtpChallenge challenge);

  Future<Either<Failure, AuthPayloadModel>> verifyOtp(VerifyOtpParams params);

  Future<Either<Failure, Unit>> logout();
}

class AuthRemoteDataSource implements AuthDataSource {
  final NetworkService _network;

  AuthRemoteDataSource(this._network);

  @override
  Future<Either<Failure, AuthAccountPayload>> register(
    RegisterParams params,
  ) =>
      guardedRequest(
        'AuthRemoteDataSource.register',
        () async {
          final response = await _network.post(
            ApiEndPoint.register,
            skipAuthRefresh: true,
            data: {
              'name': params.name.trim(),
              'email': params.email.trim(),
              'phone': params.phone,
              'password': params.password,
              'password_confirmation': params.passwordConfirmation,
            },
          );
          return AuthOutcomeModel.readAccount(checkedResponse(response).json);
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, AuthAccountPayload>> login(LoginParams params) =>
      guardedRequest(
        'AuthRemoteDataSource.login',
        () async {
          final response = await _network.post(
            ApiEndPoint.login,
            skipAuthRefresh: true,
            data: {'login': params.phone, 'password': params.password},
          );
          return AuthOutcomeModel.readAccount(checkedResponse(response).json);
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, OtpChallengeModel>> requestOtp(
    RequestOtpParams params,
  ) =>
      guardedRequest(
        'AuthRemoteDataSource.requestOtp',
        () async {
          final response = await _network.post(
            ApiEndPoint.requestOtp,
            skipAuthRefresh: true,
            data: {'phone': params.phone},
          );
          return OtpChallengeModel.fromJson(
            checkedResponse(response).json,
            phone: params.phone,
            mode: AuthMode.login,
          );
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, OtpChallengeModel>> resendOtp(
    OtpChallenge challenge,
  ) =>
      requestOtp(RequestOtpParams(phone: challenge.phone));

  @override
  Future<Either<Failure, AuthPayloadModel>> verifyOtp(
    VerifyOtpParams params,
  ) =>
      guardedRequest(
        'AuthRemoteDataSource.verifyOtp',
        () async {
          final response = await _network.post(
            ApiEndPoint.verifyOtp,
            skipAuthRefresh: true,
            data: {'phone': params.phone, 'otp': params.otp},
          );
          return AuthPayloadModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'otp_failed',
      );

  @override
  Future<Either<Failure, Unit>> logout() => guardedRequest(
        'AuthRemoteDataSource.logout',
        () async {
          checkedResponse(await _network.post(ApiEndPoint.logout));
          return unit;
        },
      );
}

class AuthMockDataSource implements AuthDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  AuthMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, AuthAccountPayload>> register(
    RegisterParams params,
  ) =>
      guardedRequest(
        'AuthMockDataSource.register',
        () async {
          await _backend.wait();
          return AuthOutcomeModel.readAccount(_backend.register(
            name: params.name,
            email: params.email,
            phone: params.phone,
            password: params.password,
            lang: await _language(),
          ));
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, AuthAccountPayload>> login(LoginParams params) =>
      guardedRequest(
        'AuthMockDataSource.login',
        () async {
          await _backend.wait();
          return AuthOutcomeModel.readAccount(_backend.login(
            phone: params.phone,
            password: params.password,
            lang: await _language(),
          ));
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, OtpChallengeModel>> requestOtp(
    RequestOtpParams params,
  ) =>
      guardedRequest(
        'AuthMockDataSource.requestOtp',
        () async {
          await _backend.wait();
          final json = _backend.requestOtp(phone: params.phone);
          return OtpChallengeModel.fromJson(
            json,
            phone: params.phone,
            mode: AuthMode.login,
          );
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, OtpChallengeModel>> resendOtp(
    OtpChallenge challenge,
  ) =>
      requestOtp(RequestOtpParams(phone: challenge.phone));

  @override
  Future<Either<Failure, AuthPayloadModel>> verifyOtp(
    VerifyOtpParams params,
  ) =>
      guardedRequest(
        'AuthMockDataSource.verifyOtp',
        () async {
          await _backend.wait();
          final json = _backend.verifyOtp(
            params.phone,
            params.otp,
            await _language(),
          );
          return AuthPayloadModel.fromJson(json);
        },
        fallbackMessage: 'otp_failed',
      );

  @override
  Future<Either<Failure, Unit>> logout() => guardedRequest(
        'AuthMockDataSource.logout',
        () async => unit,
      );
}
