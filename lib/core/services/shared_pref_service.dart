import 'package:shared_preferences/shared_preferences.dart';

abstract class SharedPrefService {
  Future<bool> writeString({required String key, required String value});
  Future<bool> writeInt({required String key, required int value});
  Future<bool> writeBool({required String key, required bool value});
  Future<bool> writeDouble({required String key, required double value});
  Future<bool> writeStringList(
      {required String key, required List<String> value});

  Future<String?> readString({required String key});
  Future<int?> readInt({required String key});
  Future<bool?> readBool({required String key});
  Future<double?> readDouble({required String key});
  Future<List<String>?> readStringList({required String key});

  Future<bool> delete({required String key});
  Future<bool> deleteAll();
  Future<bool> containsKey({required String key});
  Future<Set<String>> getKeys();
}

class SharedPrefServiceImpl implements SharedPrefService {
  final SharedPreferences _prefs;

  SharedPrefServiceImpl(this._prefs);

  @override
  Future<bool> writeString({required String key, required String value}) =>
      _prefs.setString(key, value);

  @override
  Future<bool> writeInt({required String key, required int value}) =>
      _prefs.setInt(key, value);

  @override
  Future<bool> writeBool({required String key, required bool value}) =>
      _prefs.setBool(key, value);

  @override
  Future<bool> writeDouble({required String key, required double value}) =>
      _prefs.setDouble(key, value);

  @override
  Future<bool> writeStringList(
          {required String key, required List<String> value}) =>
      _prefs.setStringList(key, value);

  @override
  Future<String?> readString({required String key}) async =>
      _prefs.getString(key);

  @override
  Future<int?> readInt({required String key}) async => _prefs.getInt(key);

  @override
  Future<bool?> readBool({required String key}) async => _prefs.getBool(key);

  @override
  Future<double?> readDouble({required String key}) async =>
      _prefs.getDouble(key);

  @override
  Future<List<String>?> readStringList({required String key}) async =>
      _prefs.getStringList(key);

  @override
  Future<bool> delete({required String key}) => _prefs.remove(key);

  @override
  Future<bool> deleteAll() => _prefs.clear();

  @override
  Future<bool> containsKey({required String key}) async =>
      _prefs.containsKey(key);

  @override
  Future<Set<String>> getKeys() async => _prefs.getKeys();
}
