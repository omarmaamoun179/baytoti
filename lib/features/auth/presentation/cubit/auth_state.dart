import 'package:equatable/equatable.dart';

import '../../domain/entities/customer.dart';

enum AuthStatus { unknown, guest, signedIn }

class AuthState extends Equatable {
  final AuthStatus status;
  final Customer? customer;

  const AuthState({this.status = AuthStatus.unknown, this.customer});

  bool get isSignedIn => status == AuthStatus.signedIn;

  @override
  List<Object?> get props => [status, customer];
}
