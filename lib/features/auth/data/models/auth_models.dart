import 'dart:convert';

import '../../../../core/network/token_store.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/otp_challenge.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.fullName,
    required super.phone,
    super.avatarUrl,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        avatarUrl: switch (json['avatar']) {
          final String url => url,
          final Map<dynamic, dynamic> image => image['url'] as String?,
          _ => null,
        },
      );

  factory CustomerModel.decode(String source) =>
      CustomerModel.fromJson(jsonMap(jsonDecode(source)));

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'avatar': avatarUrl,
      };

  String encode() => jsonEncode(toJson());
}

class OtpChallengeModel extends OtpChallenge {
  const OtpChallengeModel({
    required super.requestId,
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
        requestId: json['request_id'] as String,
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
        customer: CustomerModel.fromJson(jsonMap(json['user'])),
        isNewUser: json['is_new_user'] as bool? ?? false,
      );
}
