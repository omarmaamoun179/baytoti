import 'dart:developer' as developer;

void logError(Object error, StackTrace stackTrace, {required String reason}) {
  developer.log(
    reason,
    name: 'error',
    error: error,
    stackTrace: stackTrace,
  );
}
