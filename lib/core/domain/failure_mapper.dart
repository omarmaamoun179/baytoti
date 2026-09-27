import 'package:easy_localization/easy_localization.dart';

import '../exceptions/app_exceptions.dart';
import 'failure.dart';

Failure mapExceptionToFailure(
  Object error, {
  String fallbackMessage = 'unexpected_error',
}) {
  if (error is Failure) return error;

  return switch (error) {
    ConnectionException() => NetworkFailure(message: 'connection_failed'.tr()),

    SessionExpiredException() => ServerFailure(
        message: 'session_expired'.tr(),
        statusCode: 401,
      ),

    CacheException() => CacheFailure(
        message: _display(error.message, 'cache_error'),
      ),

    RedundantRequestException() => ServerFailure(message: fallbackMessage.tr()),

    RequestException(:final errors?) when errors.isNotEmpty =>
      ValidationFailure(
        message: _displayOrNull(error.message),
        statusCode: error.statusCode ?? 422,
        code: error.code,
        fieldErrors: flattenFieldErrors(errors),
      ),

    RequestException() => ServerFailure(
        message: _display(error.message, 'server_error'),
        statusCode: error.statusCode,
        code: error.code,
      ),

    _ => UnexpectedFailure(message: fallbackMessage.tr()),
  };
}

Map<String, String> flattenFieldErrors(Map<String, dynamic>? errors) {
  if (errors == null) return const {};

  return {
    for (final entry in errors.entries)
      entry.key: switch (entry.value) {
        final List<dynamic> list when list.isNotEmpty => '${list.first}',
        final List<dynamic> _ => '',
        final Object? value => '$value',
      },
  };
}

String _display(String message, String fallbackKey) =>
    message.trim().isEmpty ? fallbackKey.tr() : message.tr();

String? _displayOrNull(String message) =>
    message.trim().isEmpty ? null : message.tr();
