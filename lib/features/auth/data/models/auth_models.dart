import 'dart:convert';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/otp_challenge.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.fullName,
    required super.phone,
    super.email,
    super.avatarUrl,
    super.verified,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: _asString(json['id']) ?? '',
        fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        avatarUrl: switch (json['avatar']) {
          final String url => url,
          final Map<dynamic, dynamic> image => image['url'] as String?,
          _ => null,
        },
        verified: _asBool(json['status']) ?? true,
      );

  factory CustomerModel.decode(String source) =>
      CustomerModel.fromJson(jsonMap(jsonDecode(source)));

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'avatar': avatarUrl,
        'status': verified,
      };

  String encode() => jsonEncode(toJson());

  CustomerModel verifiedCopy() => CustomerModel(
        id: id,
        fullName: fullName,
        phone: phone,
        email: email,
        avatarUrl: avatarUrl,
        verified: true,
      );

  static String? _asString(Object? value) => switch (value) {
        final String text => text,
        final num number => '$number',
        _ => null,
      };

  static bool? _asBool(Object? value) => switch (value) {
        final bool flag => flag,
        final num flag => flag != 0,
        final String flag when flag == '1' || flag.toLowerCase() == 'true' =>
          true,
        final String flag when flag == '0' || flag.toLowerCase() == 'false' =>
          false,
        _ => null,
      };
}

class OtpChallengeModel extends OtpChallenge {
  const OtpChallengeModel({
    required super.phone,
    required super.mode,
    required super.expiresIn,
    required super.resendAfter,
    required super.digits,
  });

  factory OtpChallengeModel.fromJson(
    Map<String, dynamic> json, {
    required String phone,
    required AuthMode mode,
  }) =>
      OtpChallengeModel(
        phone: phone,
        mode: mode,
        expiresIn: jsonInt(json['expires_in']) ?? 120,
        resendAfter: jsonInt(json['resend_after']) ?? 30,
        digits: jsonInt(json['digits']) ?? 4,
      );
}

class AuthPayloadModel {
  final TokenPair tokens;
  final CustomerModel customer;
  final bool isNewUser;

  const AuthPayloadModel({
    required this.tokens,
    required this.customer,
    required this.isNewUser,
  });

  factory AuthPayloadModel.fromJson(Map<String, dynamic> json) =>
      AuthPayloadModel(
        tokens: TokenPair(
          accessToken: json['access_token'] as String,
          refreshToken: json['refresh_token'] as String?,
        ),
        customer: CustomerModel.fromJson(jsonMap(json['user'])).verifiedCopy(),
        isNewUser: json['is_new_user'] as bool? ?? false,
      );
}

typedef AuthAccountPayload = ({String? token, CustomerModel customer});

class AuthOutcomeModel {
  static AuthAccountPayload readAccount(Map<String, dynamic> json) {
    final userJson = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;

    if (userJson['id'] == null) throw const RequestException('auth_failed');

    return (
      token: _readToken(json),
      customer: CustomerModel.fromJson(userJson),
    );
  }

  static String? _readToken(Map<String, dynamic> json) {
    for (final key in const ['token', 'access_token', 'plain_text_token']) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
    }

    final nested = json['token'];
    if (nested is Map) {
      for (final key in const ['access_token', 'plain_text_token', 'token']) {
        final value = nested[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return null;
  }
}
