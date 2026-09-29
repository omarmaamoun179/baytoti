import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/usecases/auth_usecases.dart';

enum OtpRequestStatus { idle, submitting, sent, signedIn, failed }

class OtpRequestState extends Equatable {
  final AuthMode mode;
  final OtpRequestStatus status;
  final OtpChallenge? challenge;
  final Customer? customer;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const OtpRequestState({
    this.mode = AuthMode.login,
    this.status = OtpRequestStatus.idle,
    this.challenge,
    this.customer,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  bool get isSubmitting => status == OtpRequestStatus.submitting;

  OtpRequestState copyWith({
    AuthMode? mode,
    OtpRequestStatus? status,
    OtpChallenge? challenge,
    Customer? customer,
    String? errorMessage,
    Map<String, String>? fieldErrors,
  }) {
    return OtpRequestState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      challenge: challenge ?? this.challenge,
      customer: customer ?? this.customer,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? const {},
    );
  }

  @override
  List<Object?> get props =>
      [mode, status, challenge, customer, errorMessage, fieldErrors];
}

class OtpRequestCubit extends BaseCubit<OtpRequestState> {
  final RegisterUseCase _register;
  final LoginUseCase _login;
  final RequestOtpUseCase _requestOtp;

  OtpRequestCubit(
    this._register,
    this._login,
    this._requestOtp, {
    AuthMode mode = AuthMode.login,
  }) : super(OtpRequestState(mode: mode));

  void setMode(AuthMode mode) {
    if (mode == state.mode || state.isSubmitting) return;
    emit(OtpRequestState(mode: mode));
  }

  Future<void> submit({
    required String phone,
    required String password,
    String? fullName,
    String? email,
    String? passwordConfirmation,
    String? avatarPath,
  }) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(status: OtpRequestStatus.submitting));

    final outcome = state.mode == AuthMode.signup
        ? await _register(RegisterParams(
            name: fullName ?? '',
            email: email ?? '',
            phone: phone,
            password: password,
            passwordConfirmation: passwordConfirmation ?? '',
            avatarPath: avatarPath,
          ))
        : await _login(LoginParams(phone: phone, password: password));

    await outcome.fold(
      (failure) async => emit(state.copyWith(
        status: OtpRequestStatus.failed,
        errorMessage: failure.message,
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
      )),
      (result) => switch (result) {
        SignedIn(:final customer) => _signIn(customer),
        AwaitingVerification(:final phone) => _sendOtp(phone),
      },
    );
  }

  Future<void> _signIn(Customer customer) async => emit(state.copyWith(
        status: OtpRequestStatus.signedIn,
        customer: customer,
      ));

  Future<void> _sendOtp(String phone) async {
    final result = await _requestOtp(RequestOtpParams(phone: phone));

    result.fold(
      (failure) => emit(state.copyWith(
        status: OtpRequestStatus.failed,
        errorMessage: failure.message,
      )),
      (challenge) => emit(state.copyWith(
        status: OtpRequestStatus.sent,
        challenge: challenge,
      )),
    );
  }

  void acknowledge() => emit(state.copyWith(status: OtpRequestStatus.idle));

  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    emit(state.copyWith(
      errorMessage: state.errorMessage,
      fieldErrors: {...state.fieldErrors}..remove(field),
    ));
  }
}
