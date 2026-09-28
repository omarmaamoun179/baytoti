import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/multipart_body.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/phone.dart';
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
          final body = {
            'name': params.name.trim(),
            'email': params.email.trim(),
            'phone': wirePhone(params.phone),
            'password': params.password,
            'password_confirmation': params.passwordConfirmation,
          };
          final avatar = params.avatarPath;
          final response = await _network.post(
            ApiEndPoint.register,
            skipAuthRefresh: true,
            data: avatar == null
                ? body
                : await multipartBodyFrom({
                    ...body,
                    'avatar': FileUpload(avatar),
                  }),
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
            data: {
              'login': wirePhone(params.phone),
              'password': params.password,
            },
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
            data: {'phone': wirePhone(params.phone)},
          );
          final checked = checkedResponse(response);
          return OtpChallengeModel.fromJson(
            checked.json,
            phone: params.phone,
            mode: AuthMode.login,
            message: checked.message,
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
            data: {'phone': wirePhone(params.phone), 'otp': params.otp},
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
