import 'package:baytoti/core/network/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TokenPair', () {
    test('round-trips through JSON', () {
      const tokens = TokenPair(accessToken: 'access', refreshToken: 'refresh');

      expect(TokenPair.fromJson(tokens.toJson()), tokens);
    });

    test('is empty when the access token is blank', () {
      expect(const TokenPair(accessToken: '').isEmpty, isTrue);
      expect(const TokenPair(accessToken: 'access').isEmpty, isFalse);
    });
  });
}
