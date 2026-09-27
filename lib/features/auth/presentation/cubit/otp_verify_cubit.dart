import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/usecases/auth_usecases.dart';

enum OtpVerifyStatus { idle, verifying, verified, failed }

class OtpVerifyState extends Equatable {
  final OtpChallenge challenge;
  final String code;
  final OtpVerifyStatus status;
  final AuthSession? session;
  final int resendIn;
  final bool isResending;
  final int rejections;
  final int resends;
  final String? errorMessage;

  const OtpVerifyState({
    required this.challenge,
    this.code = '',
    this.status = OtpVerifyStatus.idle,
    this.session,
    this.resendIn = 0,
    this.isResending = false,
    this.rejections = 0,
    this.resends = 0,
    this.errorMessage,
  });

  bool get isComplete => code.length == challenge.digits;

  bool get isVerifying => status == OtpVerifyStatus.verifying;

  bool get canResend => resendIn == 0 && !isResending;

  OtpVerifyState copyWith({
    OtpChallenge? challenge,
    String? code,
    OtpVerifyStatus? status,
    AuthSession? session,
    int? resendIn,
    bool? isResending,
    int? rejections,
    int? resends,
    String? errorMessage,
  }) {
    return OtpVerifyState(
      challenge: challenge ?? this.challenge,
      code: code ?? this.code,
      status: status ?? this.status,
      session: session ?? this.session,
      resendIn: resendIn ?? this.resendIn,
      isResending: isResending ?? this.isResending,
      rejections: rejections ?? this.rejections,
      resends: resends ?? this.resends,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        challenge,
        code,
        status,
        session,
        resendIn,
        isResending,
        rejections,
        resends,
        errorMessage,
      ];
}

class OtpVerifyCubit extends BaseCubit<OtpVerifyState> {
  final VerifyOtpUseCase _verifyOtp;
  final ResendOtpUseCase _resendOtp;
  Timer? _ticker;

  OtpVerifyCubit(this._verifyOtp, this._resendOtp, OtpChallenge challenge)
      : super(OtpVerifyState(
          challenge: challenge,
          resendIn: challenge.resendAfter,
        )) {
    _startCountdown();
  }

  void _startCountdown() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.resendIn <= 0) {
        _ticker?.cancel();
        return;
      }
      emit(state.copyWith(resendIn: state.resendIn - 1));
    });
  }

  void addDigit(String digit) {
    if (state.isVerifying || state.isComplete) return;
    emit(state.copyWith(
      code: state.code + digit,
      status: OtpVerifyStatus.idle,
    ));
  }

  void removeDigit() {
    if (state.isVerifying || state.code.isEmpty) return;
    emit(state.copyWith(
      code: state.code.substring(0, state.code.length - 1),
      status: OtpVerifyStatus.idle,
    ));
  }

  Future<void> verify() async {
    if (!state.isComplete || state.isVerifying) return;
    emit(state.copyWith(status: OtpVerifyStatus.verifying));

    final result = await _verifyOtp(VerifyOtpParams(
      requestId: state.challenge.requestId,
      code: state.code,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: OtpVerifyStatus.failed,
        code: '',
        rejections: state.rejections + 1,
        errorMessage: failure.message,
      )),
      (session) => emit(state.copyWith(
        status: OtpVerifyStatus.verified,
        session: session,
      )),
    );
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    emit(state.copyWith(isResending: true));

    final result = await _resendOtp(state.challenge);

    result.fold(
      (failure) => emit(state.copyWith(
        isResending: false,
        errorMessage: failure.message,
      )),
      (challenge) {
        emit(state.copyWith(
          challenge: challenge,
          code: '',
          isResending: false,
          resendIn: challenge.resendAfter,
          resends: state.resends + 1,
        ));
        _startCountdown();
      },
    );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
