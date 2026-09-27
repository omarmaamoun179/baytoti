import 'package:equatable/equatable.dart';

import 'customer.dart';

enum AuthMode {
  login('login'),
  signup('signup');

  final String wire;

  const AuthMode(this.wire);
}

class OtpChallenge extends Equatable {
  final String requestId;
  final String phone;
  final AuthMode mode;
  final int expiresIn;
  final int resendAfter;
  final int digits;

  const OtpChallenge({
    required this.requestId,
    required this.phone,
    required this.mode,
    required this.expiresIn,
    required this.resendAfter,
    required this.digits,
  });

  @override
  List<Object?> get props =>
      [requestId, phone, mode, expiresIn, resendAfter, digits];
}

class AuthSession extends Equatable {
  final Customer customer;
  final bool isNewUser;

  const AuthSession({required this.customer, required this.isNewUser});

  @override
  List<Object?> get props => [customer, isNewUser];
}

class RequestOtpParams extends Equatable {
  final String phone;
  final AuthMode mode;
  final String? fullName;

  const RequestOtpParams({
    required this.phone,
    required this.mode,
    this.fullName,
  });

  @override
  List<Object?> get props => [phone, mode, fullName];
}

class VerifyOtpParams extends Equatable {
  final String requestId;
  final String code;

  const VerifyOtpParams({required this.requestId, required this.code});

  @override
  List<Object?> get props => [requestId, code];
}
