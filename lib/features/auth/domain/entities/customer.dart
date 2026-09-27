import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String? avatarUrl;

  const Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, fullName, phone, avatarUrl];
}
