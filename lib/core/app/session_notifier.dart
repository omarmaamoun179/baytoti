import 'package:flutter/foundation.dart';

class SessionNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool _isResolved = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isResolved => _isResolved;

  void signedIn() => _set(authenticated: true, resolved: true);

  void signedOut() => _set(authenticated: false, resolved: true);

  void markResolved() => _set(authenticated: _isAuthenticated, resolved: true);

  void _set({required bool authenticated, required bool resolved}) {
    if (_isAuthenticated == authenticated && _isResolved == resolved) return;
    _isAuthenticated = authenticated;
    _isResolved = resolved;
    notifyListeners();
  }
}
