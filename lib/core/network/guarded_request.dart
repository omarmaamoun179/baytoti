import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';

import '../domain/failure.dart';
import '../domain/failure_mapper.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/app_logger.dart';

Future<Either<Failure, T>> guardedRequest<T>(
  String reason,
  Future<T> Function() call, {
  String fallbackMessage = 'unexpected_error',
  Map<int, String> messageForStatus = const {},
}) async {
  try {
    return Right(await call());
  } on AppException catch (e, s) {
    logError(e, s, reason: reason);
    return Left(mapExceptionToFailure(
      _renamed(e, messageForStatus),
      fallbackMessage: fallbackMessage,
    ));
  } catch (e, s) {
    logError(e, s, reason: reason);
    return Left(UnexpectedFailure(message: fallbackMessage.tr()));
  }
}

Future<Either<Failure, T>> guardedStorage<T>(
  String reason,
  Future<T> Function() call, {
  String fallbackMessage = 'cache_error',
}) async {
  try {
    return Right(await call());
  } on FormatException catch (e, s) {
    logError(e, s, reason: reason);
    return Left(UnexpectedFailure(message: 'unexpected_error'.tr()));
  } on TypeError catch (e, s) {
    logError(e, s, reason: reason);
    return Left(UnexpectedFailure(message: 'unexpected_error'.tr()));
  } catch (e, s) {
    logError(e, s, reason: reason);
    return Left(CacheFailure(message: fallbackMessage.tr()));
  }
}

AppException _renamed(AppException e, Map<int, String> renames) {
  if (e is! RequestException) return e;

  final message = renames[e.statusCode];
  if (message == null) return e;

  return RequestException(
    message,
    code: e.code,
    statusCode: e.statusCode,
    errors: e.errors,
    details: e.details,
  );
}
