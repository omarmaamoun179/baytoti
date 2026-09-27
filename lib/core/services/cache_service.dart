import 'secure_storage_service.dart';
import 'shared_pref_service.dart';

abstract class CacheService {
  Future<bool> saveUserData(String userData);
  Future<String?> getUserData();
  Future<bool> clearUserData();

  Future<String?> getLanguageCode();
  Future<void> setLanguageCode(String languageCode);

  Future<bool> saveUserLocation(String location);
  Future<String?> getUserLocation();
  Future<bool> clearUserLocation();

  Future<bool?> getOnboardingSeen();
  Future<bool> setOnboardingSeen(bool seen);

  Future<void> clearSession();
}

class CacheServiceImpl implements CacheService {
  static const _userDataKey = 'user_data';
  static const _languageCodeKey = 'language_code';
  static const _locationKey = 'user_location';
  static const _onboardingSeenKey = 'onboarding_seen';

  final SharedPrefService _sharedPref;
  final SecureStorageService _secureStorage;

  CacheServiceImpl(this._sharedPref, this._secureStorage);

  @override
  Future<String?> getUserData() => _secureStorage.read(key: _userDataKey);

  @override
  Future<bool> saveUserData(String userData) async {
    await _secureStorage.write(key: _userDataKey, value: userData);
    return true;
  }

  @override
  Future<bool> clearUserData() async {
    await _secureStorage.delete(key: _userDataKey);
    return true;
  }

  @override
  Future<String?> getLanguageCode() =>
      _sharedPref.readString(key: _languageCodeKey);

  @override
  Future<void> setLanguageCode(String languageCode) =>
      _sharedPref.writeString(key: _languageCodeKey, value: languageCode);

  @override
  Future<String?> getUserLocation() =>
      _sharedPref.readString(key: _locationKey);

  @override
  Future<bool> saveUserLocation(String location) =>
      _sharedPref.writeString(key: _locationKey, value: location);

  @override
  Future<bool> clearUserLocation() => _sharedPref.delete(key: _locationKey);

  @override
  Future<bool?> getOnboardingSeen() =>
      _sharedPref.readBool(key: _onboardingSeenKey);

  @override
  Future<bool> setOnboardingSeen(bool seen) =>
      _sharedPref.writeBool(key: _onboardingSeenKey, value: seen);

  @override
  Future<void> clearSession() async {
    await clearUserData();
    await clearUserLocation();
  }
}
