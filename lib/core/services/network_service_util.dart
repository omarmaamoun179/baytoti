import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../network/token_store.dart';
import 'app_service_info.dart';
import 'cache_service.dart';

abstract class NetworkServiceUtil {
  Future<String?> getCurrentAccessToken();
  Future<String?> getLanguageCode();
  Future<String> getAppVersion();
  String getPlatformType();
  Future<void> clearCurrentUserData();
}

class NetworkServiceUtilImpl implements NetworkServiceUtil {
  NetworkServiceUtilImpl(this._cacheService, this._tokenStore, this._appInfo);

  final CacheService _cacheService;

  final TokenStore _tokenStore;

  final AppInfo _appInfo;

  String? _cachedAppVersion;

  @override
  Future<String?> getCurrentAccessToken() async =>
      (await _tokenStore.read())?.accessToken;

  @override
  Future<String?> getLanguageCode() async {
    final language = await _cacheService.getLanguageCode();
    return language?.split('_').first;
  }

  @override
  Future<String> getAppVersion() async =>
      _cachedAppVersion ??= (_appInfo.version ?? '1.0.0').split('-').first;

  @override
  String getPlatformType() {
    if (kIsWeb) return 'web';
    return Platform.isAndroid ? 'android' : 'ios';
  }

  @override
  Future<void> clearCurrentUserData() async {
    await _tokenStore.clear();
    await _cacheService.clearSession();
  }
}
