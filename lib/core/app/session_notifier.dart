import 'package:flutter/foundation.dart';

class SessionNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool _isResolved = false;

  bool? _hasLocation;

  bool get isAuthenticated => _isAuthenticated;
  bool get isResolved => _isResolved;

  bool get isLocationResolved => _hasLocation != null;
  bool get hasLocation => _hasLocation ?? false;

  void signedIn() => _set(authenticated: true, resolved: true);

  void signedOut() {
    final changed = _hasLocation != null;
    _hasLocation = null;
    if (!_set(authenticated: false, resolved: true) && changed) {
      notifyListeners();
    }
  }

  void markResolved() => _set(authenticated: _isAuthenticated, resolved: true);

  void locationKnown(bool hasLocation) {
    if (_hasLocation == hasLocation) return;
    _hasLocation = hasLocation;
    notifyListeners();
  }

  bool _set({required bool authenticated, required bool resolved}) {
    if (_isAuthenticated == authenticated && _isResolved == resolved) {
      return false;
    }
    _isAuthenticated = authenticated;
    _isResolved = resolved;
    notifyListeners();
    return true;
  }
}
