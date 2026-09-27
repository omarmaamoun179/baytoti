import 'package:dio/dio.dart';

import '../exceptions/app_exceptions.dart';

class ApiResponse {
  final int statusCode;

  final dynamic body;

  const ApiResponse({required this.statusCode, this.body});

  factory ApiResponse.from(Response<dynamic> response) =>
      ApiResponse(statusCode: response.statusCode ?? 0, body: response.data);

  bool get isOk => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> get json =>
      body is Map ? Map<String, dynamic>.from(body as Map) : const {};

  Map<String, dynamic> get _error => switch (json['error']) {
        final Map<dynamic, dynamic> error => Map<String, dynamic>.from(error),
        _ => const {},
      };

  void ensureOk() {
    if (isOk) return;

    final error = _error;
    final message = error['message'] as String? ?? '';
    final field = error['field'] as String?;

    throw RequestException(
      message.isNotEmpty ? message : 'request_failed',
      code: error['code'] as String?,
      statusCode: statusCode,
      errors: field == null || message.isEmpty ? null : {field: message},
      details: switch (error['details']) {
        final Map<dynamic, dynamic> details =>
          Map<String, dynamic>.from(details),
        _ => null,
      },
    );
  }
}

ApiResponse checkedResponse(Response<dynamic> response) =>
    ApiResponse.from(response)..ensureOk();
