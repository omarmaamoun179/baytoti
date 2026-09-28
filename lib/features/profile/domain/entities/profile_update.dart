import 'package:equatable/equatable.dart';

class ProfileUpdate extends Equatable {
  static const int nameMaxLength = 100;

  final String name;
  final String email;
  final String? avatarPath;

  const ProfileUpdate({
    required this.name,
    required this.email,
    this.avatarPath,
  });

  @override
  List<Object?> get props => [name, email, avatarPath];
}
