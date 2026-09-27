import 'dart:convert';

import '../../../../core/exceptions/app_exceptions.dart';
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
        id: jsonId(json['id']) ?? '',
        fullName: jsonString(json['full_name'] ?? json['name']) ?? '',
        phone: jsonString(json['phone']) ?? '',
        email: jsonString(json['email']),
        avatarUrl: switch (json['avatar']) {
          final String url => url,
          final Map<dynamic, dynamic> image => jsonString(image['url']),
          _ => null,
        },
        verified: jsonBool(json['status']) ?? true,
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
}

class OtpChallengeModel extends OtpChallenge {
  const OtpChallengeModel({
    required super.phone,
    required super.mode,
    required super.expiresIn,
    required super.resendAfter,
    required super.digits,
    super.demoCode,
  });

  factory OtpChallengeModel.fromJson(
    Map<String, dynamic> json, {
    required String phone,
    required AuthMode mode,
    String message = '',
  }) =>
      OtpChallengeModel(
        phone: phone,
        mode: mode,
        expiresIn: jsonInt(json['expires_in']) ?? 180,
        resendAfter: jsonInt(json['resend_after']) ?? 60,
        digits: jsonInt(json['digits']) ?? 6,
        demoCode: jsonString(json['otp']) ?? demoOtpFrom(message),
      );

  static String? demoOtpFrom(String message) {
    final colon = message.lastIndexOf(':');
    if (colon == -1) return null;
    final code = message.substring(colon + 1).trim();
    return RegExp(r'^\d+$').hasMatch(code) ? code : null;
  }
}

class AuthPayloadModel {
  final String? token;
  final String? refreshToken;
  final CustomerModel? customer;
  final bool isNewUser;

  const AuthPayloadModel({
    this.token,
    this.refreshToken,
    this.customer,
    this.isNewUser = false,
  });

  factory AuthPayloadModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;

    return AuthPayloadModel(
      token: AuthOutcomeModel.readToken(json),
      refreshToken: json['refresh_token'] as String?,
      customer: userJson['id'] == null ? null : CustomerModel.fromJson(userJson),
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }
}

typedef AuthAccountPayload = ({String? token, CustomerModel customer});

class AuthOutcomeModel {
  static AuthAccountPayload readAccount(Map<String, dynamic> json) {
    final userJson = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;

    if (userJson['id'] == null) throw const RequestException('auth_failed');

    return (
      token: readToken(json),
      customer: CustomerModel.fromJson(userJson),
    );
  }

  static String? readToken(Map<String, dynamic> json) {
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
