import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const List<String> errorMessageKeys = [
  'connection_error',
  'session_expired',
  'cache_error',
  'request_failed',
  'connection_failed',
  'server_error',
  'unexpected_error',
  'auth_failed',
  'otp_failed',
  'home_failed',
  'stores_failed',
  'cart_failed',
  'cart_update_failed',
  'favourite_failed',
  'notifications_failed',
  'profile_failed',
  'profile_update_failed',
  'explore_failed',
  'search_failed',
  'product_failed',
  'product_not_found',
  'family_failed',
  'family_not_found',
  'checkout_failed',
  'order_place_failed',
  'order_failed',
  'order_not_found',
  'order_cancel_failed',
  'location_failed',
  'addresses_failed',
  'address_not_found',
  'review_failed',
  'review_not_allowed',
];

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final en = _load('en');
  final ar = _load('ar');

  group('error messages are translated', () {
    for (final key in errorMessageKeys) {
      test('$key exists in both locales', () {
        expect(en, contains(key), reason: 'missing from en.json');
        expect(ar, contains(key), reason: 'missing from ar.json');
      });

      test('$key is not left as its own slug', () {
        expect(en[key], isNot(key));
        expect(ar[key], isNot(key));
        expect((en[key] as String).trim(), isNotEmpty);
        expect((ar[key] as String).trim(), isNotEmpty);
      });
    }
  });

  group('the locales agree', () {
    test('every en key has an ar counterpart, and the reverse', () {
      expect(ar.keys.toSet(), en.keys.toSet());
    });

    test('no value is left empty', () {
      final blank = [
        for (final entry in {...en, ...ar}.entries)
          if ((entry.value as String).trim().isEmpty) entry.key,
      ];

      expect(blank, isEmpty);
    });
  });
}
