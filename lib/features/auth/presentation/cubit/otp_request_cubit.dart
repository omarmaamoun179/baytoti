import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/usecases/auth_usecases.dart';

enum OtpRequestStatus { idle, submitting, sent, failed }

class OtpRequestState extends Equatable {
  final AuthMode mode;
  final OtpRequestStatus status;
  final OtpChallenge? challenge;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const OtpRequestState({
    this.mode = AuthMode.login,
    this.status = OtpRequestStatus.idle,
    this.challenge,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  bool get isSubmitting => status == OtpRequestStatus.submitting;

  OtpRequestState copyWith({
    AuthMode? mode,
    OtpRequestStatus? status,
    OtpChallenge? challenge,
    String? errorMessage,
    Map<String, String>? fieldErrors,
  }) {
    return OtpRequestState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      challenge: challenge ?? this.challenge,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? const {},
    );
  }

  @override
  List<Object?> get props => [mode, status, challenge, errorMessage, fieldErrors];
}

class OtpRequestCubit extends BaseCubit<OtpRequestState> {
  final RequestOtpUseCase _requestOtp;

  OtpRequestCubit(this._requestOtp, {AuthMode mode = AuthMode.login})
      : super(OtpRequestState(mode: mode));

  void setMode(AuthMode mode) {
    if (mode == state.mode || state.isSubmitting) return;
    emit(OtpRequestState(mode: mode));
  }

  Future<void> submit({required String phone, String? fullName}) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(status: OtpRequestStatus.submitting));

    final result = await _requestOtp(RequestOtpParams(
      phone: phone,
      mode: state.mode,
      fullName: state.mode == AuthMode.signup ? fullName : null,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: OtpRequestStatus.failed,
        errorMessage: failure.message,
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
      )),
      (challenge) => emit(state.copyWith(
        status: OtpRequestStatus.sent,
        challenge: challenge,
      )),
    );
  }

  void acknowledge() => emit(state.copyWith(status: OtpRequestStatus.idle));
}
