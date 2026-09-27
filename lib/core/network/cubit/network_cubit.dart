import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../abstract/base_cubit.dart';
import '../network_info.dart';
import 'network_state.dart';

class NetworkCubit extends BaseCubit<NetworkState> {
  final NetworkInfo _networkInfo;
  StreamSubscription<InternetStatus>? _subscription;

  NetworkCubit(this._networkInfo) : super(const NetworkInitial()) {
    _monitorConnection();
  }

  void _monitorConnection() {
    _subscription = _networkInfo.onStatusChange.listen((status) {
      switch (status) {
        case InternetStatus.connected:
          emit(const NetworkConnected());
        case InternetStatus.disconnected:
          emit(const NetworkDisconnected());
      }
    });
  }

  Future<bool> checkConnection() async {
    final hasAccess = await _networkInfo.hasInternetAccess;
    if (hasAccess) {
      emit(const NetworkConnected());
    }
    return hasAccess;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
