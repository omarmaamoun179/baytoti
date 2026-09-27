import 'package:equatable/equatable.dart';

import 'customer.dart';

enum AuthMode {
  login('login'),
  signup('signup');

  final String wire;

  const AuthMode(this.wire);
}

class OtpChallenge extends Equatable {
  final String phone;
  final AuthMode mode;
  final int expiresIn;
  final int resendAfter;
  final int digits;

  const OtpChallenge({
    required this.phone,
    required this.mode,
    required this.expiresIn,
    required this.resendAfter,
    required this.digits,
  });

  @override
  List<Object?> get props => [phone, mode, expiresIn, resendAfter, digits];
}

class AuthSession extends Equatable {
  final Customer customer;
  final bool isNewUser;

  const AuthSession({required this.customer, required this.isNewUser});

  @override
  List<Object?> get props => [customer, isNewUser];
}

sealed class AuthOutcome extends Equatable {
  const AuthOutcome();
}

class SignedIn extends AuthOutcome {
  final Customer customer;
  final bool isNewUser;

  const SignedIn(this.customer, {this.isNewUser = false});

  @override
  List<Object?> get props => [customer, isNewUser];
}

class AwaitingVerification extends AuthOutcome {
  final String phone;

  const AwaitingVerification(this.phone);

  @override
  List<Object?> get props => [phone];
}

class RequestOtpParams extends Equatable {
  final String phone;

  const RequestOtpParams({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class VerifyOtpParams extends Equatable {
  final String phone;
  final String otp;

  const VerifyOtpParams({required this.phone, required this.otp});

  @override
  List<Object?> get props => [phone, otp];
}

class RegisterParams extends Equatable {
  static const int nameMinLength = 3;
  static const int nameMaxLength = 100;
  static const int passwordMinLength = 8;

  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props => [name, email, phone];

  @override
  String toString() => 'RegisterParams($phone, $email, password: ***)';
}

class LoginParams extends Equatable {
  final String phone;
  final String password;

  const LoginParams({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone];

  @override
  String toString() => 'LoginParams($phone, password: ***)';
}
