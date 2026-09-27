import 'dart:convert';

import '../services/secure_storage_service.dart';

class TokenPair {
  final String accessToken;
  final String? refreshToken;

  const TokenPair({required this.accessToken, this.refreshToken});

  bool get isEmpty => accessToken.isEmpty;

  TokenPair copyWith({String? accessToken, String? refreshToken}) => TokenPair(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
      );

  Map<String, dynamic> toMap() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
      };

  factory TokenPair.fromMap(Map<String, dynamic> map) => TokenPair(
        accessToken: (map['access_token'] ?? '') as String,
        refreshToken: map['refresh_token'] as String?,
      );

  String toJson() => json.encode(toMap());

  factory TokenPair.fromJson(String source) =>
      TokenPair.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant TokenPair other) =>
      identical(this, other) ||
      (other.accessToken == accessToken &&
          other.refreshToken == refreshToken);

  @override
  int get hashCode => accessToken.hashCode ^ refreshToken.hashCode;

  @override
  String toString() => 'TokenPair(accessToken: ***, '
      'refreshToken: ${refreshToken == null ? 'null' : '***'})';
}

abstract class TokenStore {
  Future<TokenPair?> read();
  Future<void> save(TokenPair tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  final SecureStorageService _secureStorage;

  SecureTokenStore(this._secureStorage);

  @override
  Future<TokenPair?> read() async {
    final accessToken =
        await _secureStorage.read(key: SecureStorageService.authTokenKey);
    if (accessToken == null || accessToken.isEmpty) return null;
    final refreshToken =
        await _secureStorage.read(key: SecureStorageService.refreshTokenKey);
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<void> save(TokenPair tokens) async {
    await _secureStorage.write(
      key: SecureStorageService.authTokenKey,
      value: tokens.accessToken,
    );
    final refreshToken = tokens.refreshToken;
    if (refreshToken != null) {
      await _secureStorage.write(
        key: SecureStorageService.refreshTokenKey,
        value: refreshToken,
      );
    }
  }

  @override
  Future<void> clear() async {
    await _secureStorage.delete(key: SecureStorageService.authTokenKey);
    await _secureStorage.delete(key: SecureStorageService.refreshTokenKey);
  }
}
