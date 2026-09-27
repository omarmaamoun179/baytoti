import 'package:dio/dio.dart';

import '../exceptions/app_exceptions.dart';

class ApiResponse {
  final int statusCode;

  final dynamic body;

  const ApiResponse({required this.statusCode, this.body});

  factory ApiResponse.from(Response<dynamic> response) =>
      ApiResponse(statusCode: response.statusCode ?? 0, body: response.data);

  bool get isOk => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> get _envelope =>
      body is Map ? Map<String, dynamic>.from(body as Map) : const {};

  Map<String, dynamic> get json {
    final envelope = _envelope;
    final data = envelope['data'];
    return data is Map ? Map<String, dynamic>.from(data) : envelope;
  }

  bool get _succeeded {
    final success = _envelope['success'];
    return success is bool ? success : isOk;
  }

  Map<String, dynamic> get _errors => switch (_envelope['errors']) {
        final Map<dynamic, dynamic> errors => Map<String, dynamic>.from(errors),
        _ => const {},
      };

  void ensureOk() {
    if (_succeeded) return;

    final message = _envelope['message'] as String? ?? '';

    throw RequestException(
      message.isNotEmpty ? message : 'request_failed',
      statusCode: statusCode,
      errors: _errors.isEmpty ? null : _errors,
    );
  }
}

ApiResponse checkedResponse(Response<dynamic> response) =>
    ApiResponse.from(response)..ensureOk();
