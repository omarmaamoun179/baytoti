import 'package:flutter/material.dart';

import '../di/di_exports.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (sl.isRegistered<NetworkCubit>()) {
        sl<NetworkCubit>().checkConnection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
