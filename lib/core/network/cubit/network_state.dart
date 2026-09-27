import 'package:equatable/equatable.dart';

sealed class NetworkState extends Equatable {
  const NetworkState();

  @override
  List<Object?> get props => [];
}

final class NetworkInitial extends NetworkState {
  const NetworkInitial();
}

final class NetworkConnected extends NetworkState {
  const NetworkConnected();
}

final class NetworkDisconnected extends NetworkState {
  const NetworkDisconnected();
}
