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
  Future<Either<Failure, OtpChallengeModel>> requestOtp(RequestOtpParams params);

  Future<Either<Failure, OtpChallengeModel>> resendOtp(OtpChallenge challenge);

  Future<Either<Failure, AuthPayloadModel>> verifyOtp(VerifyOtpParams params);

  Future<Either<Failure, Unit>> logout();
}

class AuthRemoteDataSource implements AuthDataSource {
  final NetworkService _network;

  AuthRemoteDataSource(this._network);

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
            data: {
              'phone': params.phone,
              'mode': params.mode.wire,
              if (params.mode == AuthMode.signup) 'full_name': params.fullName,
            },
          );
          return OtpChallengeModel.fromJson(
            checkedResponse(response).json,
            phone: params.phone,
            mode: params.mode,
          );
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, OtpChallengeModel>> resendOtp(
    OtpChallenge challenge,
  ) =>
      guardedRequest(
        'AuthRemoteDataSource.resendOtp',
        () async {
          final response = await _network.post(
            ApiEndPoint.resendOtp,
            skipAuthRefresh: true,
            data: {'request_id': challenge.requestId},
          );
          final json = checkedResponse(response).json;
          return OtpChallengeModel.fromJson(
            {'request_id': challenge.requestId, ...json},
            phone: challenge.phone,
            mode: challenge.mode,
          );
        },
        fallbackMessage: 'auth_failed',
      );

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
            data: {'request_id': params.requestId, 'code': params.code},
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
  Future<Either<Failure, OtpChallengeModel>> requestOtp(
    RequestOtpParams params,
  ) =>
      guardedRequest(
        'AuthMockDataSource.requestOtp',
        () async {
          await _backend.wait();
          final json = _backend.requestOtp(
            phone: params.phone,
            mode: params.mode.wire,
            fullName: params.fullName,
          );
          return OtpChallengeModel.fromJson(
            json,
            phone: params.phone,
            mode: params.mode,
          );
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, OtpChallengeModel>> resendOtp(
    OtpChallenge challenge,
  ) =>
      guardedRequest(
        'AuthMockDataSource.resendOtp',
        () async {
          await _backend.wait();
          final json = _backend.resendOtp(
            challenge.requestId,
            await _language(),
          );
          return OtpChallengeModel.fromJson(
            json,
            phone: challenge.phone,
            mode: challenge.mode,
          );
        },
        fallbackMessage: 'auth_failed',
      );

  @override
  Future<Either<Failure, AuthPayloadModel>> verifyOtp(
    VerifyOtpParams params,
  ) =>
      guardedRequest(
        'AuthMockDataSource.verifyOtp',
        () async {
          await _backend.wait();
          final json = _backend.verifyOtp(
            params.requestId,
            params.code,
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
