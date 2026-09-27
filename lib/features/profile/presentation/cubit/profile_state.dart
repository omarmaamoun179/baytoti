import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/customer.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Customer? customer;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.customer,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    Customer? customer,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      customer: customer ?? this.customer,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, customer, errorMessage];
}
