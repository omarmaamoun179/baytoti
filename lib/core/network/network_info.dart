import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class NetworkInfo {
  Future<bool> get hasInternetAccess;

  Stream<InternetStatus> get onStatusChange;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection _connection;

  NetworkInfoImpl(this._connection);

  @override
  Future<bool> get hasInternetAccess => _connection.hasInternetAccess;

  @override
  Stream<InternetStatus> get onStatusChange => _connection.onStatusChange;
}
