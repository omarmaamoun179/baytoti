import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomNavigatorObserver extends NavigatorObserver {
  final String navigatorName;

  CustomNavigatorObserver({required this.navigatorName});

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _report('push', _nameOf(route), _nameOf(previousRoute));
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _report('pop', _nameOf(route), _nameOf(previousRoute));
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _report('replace', _nameOf(newRoute), _nameOf(oldRoute));
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    _report('remove', _nameOf(route), _nameOf(previousRoute));
  }

  String _nameOf(Route? route) =>
      route?.settings.name ?? route?.runtimeType.toString() ?? 'none';

  void _report(String action, String current, String previous) {
    if (kDebugMode) {
      debugPrint('🧭 [$navigatorName] $action: $current (from $previous)');
    }
  }
}
