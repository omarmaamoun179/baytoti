import 'package:equatable/equatable.dart';

import '../../domain/entities/profile.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Profile? profile;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
