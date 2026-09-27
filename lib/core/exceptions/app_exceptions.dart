sealed class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class ConnectionException extends AppException {
  const ConnectionException([super.message = 'connection_error']);
}

class RequestException extends AppException {
  final String? code;

  final int? statusCode;

  final Map<String, dynamic>? errors;

  final Map<String, dynamic>? details;

  const RequestException(
    super.message, {
    this.code,
    this.statusCode,
    this.errors,
    this.details,
  });
}

class RedundantRequestException extends AppException {
  const RedundantRequestException(super.message);
}

class SessionExpiredException extends AppException {
  const SessionExpiredException([super.message = 'session_expired']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'cache_error']);
}
