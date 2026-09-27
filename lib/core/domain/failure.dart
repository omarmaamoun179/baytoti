import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({this.message, this.statusCode, this.code});

  final String? message;

  final int? statusCode;

  final String? code;

  @override
  List<Object?> get props => [message, statusCode, code];

  @override
  String toString() => '$runtimeType($statusCode, $code): $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message, super.statusCode, super.code});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message, super.statusCode, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message, super.statusCode, super.code});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message, super.statusCode, super.code});
}

class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure({
    super.message,
    super.statusCode = 422,
    super.code,
    this.fieldErrors = const {},
  });

  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  String? operator [](String field) => fieldErrors[field];

  @override
  List<Object?> get props => [...super.props, fieldErrors];

  @override
  String toString() => '$runtimeType($statusCode): $message $fieldErrors';
}
