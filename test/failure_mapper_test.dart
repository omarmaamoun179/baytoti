import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/failure_mapper.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('failure type', () {
    test('a transport failure is a NetworkFailure, not a server one', () {
      final failure = mapExceptionToFailure(const ConnectionException());

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'connection_failed');
    });

    test('a server rejection is a ServerFailure carrying the status', () {
      final failure = mapExceptionToFailure(
        const RequestException('order_not_found', statusCode: 404),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 404);
      expect(failure.message, 'order_not_found');
    });

    test('an expired session reads as a 401', () {
      final failure = mapExceptionToFailure(const SessionExpiredException());

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
      expect(failure.message, 'session_expired');
    });

    test('a cache error is a CacheFailure', () {
      final failure = mapExceptionToFailure(const CacheException());

      expect(failure, isA<CacheFailure>());
      expect(failure.message, 'cache_error');
    });

    test('an unrecognized error is unexpected, with the caller key', () {
      final failure = mapExceptionToFailure(
        StateError('bad'),
        fallbackMessage: 'oops',
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'oops');
      expect(failure.message, isNot(contains('Bad state')));
    });

    test('a failure passes through untouched', () {
      const original = NetworkFailure(message: 'already mapped');

      expect(mapExceptionToFailure(original), same(original));
    });
  });

  group('what a message may leak', () {
    test('a pending-request URL never becomes a message', () {
      final failure = mapExceptionToFailure(
        const RedundantRequestException(
          'Request is already pending for https://host/api/v1/orders',
        ),
        fallbackMessage: 'orders_failed',
      );

      expect(failure.message, 'orders_failed');
      expect(failure.message, isNot(contains('https://')));
    });

    test('an empty message falls back rather than showing a blank toast', () {
      final failure = mapExceptionToFailure(const RequestException(''));

      expect(failure.message, 'server_error');
    });

    test("the API's own prose survives, since it is not a key", () {
      final failure = mapExceptionToFailure(
        const RequestException(
          'These credentials do not match our records.',
          statusCode: 401,
        ),
      );

      expect(failure.message, 'These credentials do not match our records.');
    });
  });

  group('validation', () {
    test('a 422 with errors becomes a ValidationFailure with the fields', () {
      final failure = mapExceptionToFailure(
        const RequestException(
          'The given data was invalid.',
          statusCode: 422,
          errors: {
            'email': ['The email has already been taken.', 'second'],
            'phone': ['The phone field is required.'],
          },
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, {
        'email': 'The email has already been taken.',
        'phone': 'The phone field is required.',
      });
      expect(failure.message, 'The given data was invalid.');
    });

    test('errors without a summary message leave the message null', () {
      final failure = mapExceptionToFailure(
        const RequestException(
          '',
          statusCode: 422,
          errors: {
            'otp': ['The selected otp is invalid.'],
          },
        ),
      );

      expect(failure.message, isNull);
      expect(
        (failure as ValidationFailure)['otp'],
        'The selected otp is invalid.',
      );
    });

    test('an empty errors map is a plain server failure', () {
      final failure = mapExceptionToFailure(
        const RequestException('nope', statusCode: 422, errors: {}),
      );

      expect(failure, isA<ServerFailure>());
    });

    test('a 422 defaults to 422 when the exception carries no status', () {
      final failure = mapExceptionToFailure(
        const RequestException(
          'invalid',
          errors: {
            'email': ['taken'],
          },
        ),
      );

      expect(failure.statusCode, 422);
    });
  });

  group('flattenFieldErrors', () {
    test('takes the first message per field', () {
      expect(
        flattenFieldErrors({
          'email': ['first', 'second'],
        }),
        {'email': 'first'},
      );
    });

    test('keeps the API dot notation', () {
      expect(
        flattenFieldErrors({
          'colors.0.variants.0.size_id': ['required'],
        }),
        {'colors.0.variants.0.size_id': 'required'},
      );
    });

    test('tolerates a bare string, an empty list and a null map', () {
      expect(flattenFieldErrors({'email': 'taken'}), {'email': 'taken'});
      expect(flattenFieldErrors({'email': <String>[]}), {'email': ''});
      expect(flattenFieldErrors(null), isEmpty);
    });
  });

  group('equality', () {
    test('two failures of the same type and message are equal', () {
      expect(
        const ServerFailure(message: 'x', statusCode: 500),
        const ServerFailure(message: 'x', statusCode: 500),
      );
    });

    test('the type is part of the identity', () {
      expect(
        const ServerFailure(message: 'x'),
        isNot(const NetworkFailure(message: 'x')),
      );
    });

    test('field errors are compared by value', () {
      expect(
        const ValidationFailure(fieldErrors: {'a': '1'}),
        const ValidationFailure(fieldErrors: {'a': '1'}),
      );
      expect(
        const ValidationFailure(fieldErrors: {'a': '1'}),
        isNot(const ValidationFailure(fieldErrors: {'a': '2'})),
      );
    });
  });
}
