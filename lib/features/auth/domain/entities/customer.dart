import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final bool verified;

  const Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.verified = true,
  });

  @override
  List<Object?> get props => [id, fullName, phone, email, avatarUrl, verified];
}
