import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cache_envelope.dart';

class PrefsCacheStore {
  PrefsCacheStore(this._prefs, {required String namespace})
      : _ns = '$namespace:';

  final SharedPreferences _prefs;
  final String _ns;

  String _namespaced(String key) => '$_ns$key';

  CacheEnvelope? read(String key) {
    final String? raw = _prefs.getString(_namespaced(key));
    if (raw == null) return null;
    try {
      return CacheEnvelope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      unawaited(_prefs.remove(_namespaced(key)));
      return null;
    }
  }

  Future<void> write(
    String key,
    Map<String, dynamic> payload, {
    DateTime? savedAt,
  }) =>
      _prefs.setString(
        _namespaced(key),
        jsonEncode(
          CacheEnvelope(savedAt: savedAt ?? DateTime.now(), payload: payload)
              .toJson(),
        ),
      );

  Future<void> delete(String key) => _prefs.remove(_namespaced(key));

  Future<void> deleteByPrefix(String prefix) async {
    final String fullPrefix = _namespaced(prefix);
    final List<String> matching =
        _prefs.getKeys().where((k) => k.startsWith(fullPrefix)).toList();
    for (final String key in matching) {
      await _prefs.remove(key);
    }
  }

  Future<void> sweepExpired(Duration maxAge) async {
    final DateTime cutoff = DateTime.now().subtract(maxAge);
    final List<String> keys =
        _prefs.getKeys().where((k) => k.startsWith(_ns)).toList();
    for (final String key in keys) {
      final String? raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        final env =
            CacheEnvelope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (env.savedAt.isBefore(cutoff)) await _prefs.remove(key);
      } catch (_) {
        await _prefs.remove(key);
      }
    }
  }

  Future<void> capEntries(int max) async {
    final List<String> keys =
        _prefs.getKeys().where((k) => k.startsWith(_ns)).toList();
    if (keys.length <= max) return;
    final List<MapEntry<String, DateTime>> withTimes = [];
    for (final String key in keys) {
      final String? raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        final env =
            CacheEnvelope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        withTimes.add(MapEntry(key, env.savedAt));
      } catch (_) {
        await _prefs.remove(key);
      }
    }
    withTimes.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in withTimes.skip(max)) {
      await _prefs.remove(entry.key);
    }
  }

  Future<void> clear() async {
    final List<String> keys =
        _prefs.getKeys().where((k) => k.startsWith(_ns)).toList();
    for (final String key in keys) {
      await _prefs.remove(key);
    }
  }
}
