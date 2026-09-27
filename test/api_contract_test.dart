import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/failure_mapper.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_response.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiResponse', () {
    test('a 2xx body is the resource itself', () {
      const response = ApiResponse(statusCode: 200, body: {'id': 'prd_1'});

      expect(response.isOk, isTrue);
      expect(response.json['id'], 'prd_1');
      expect(response.ensureOk, returnsNormally);
    });

    test('an error carries its message, status and field errors', () {
      const response = ApiResponse(
        statusCode: 422,
        body: {
          'success': false,
          'message': 'الكمية المطلوبة غير متوفرة',
          'data': null,
          'errors': {
            'items.0.quantity': ['الكمية المطلوبة غير متوفرة'],
          },
        },
      );

      expect(
        response.ensureOk,
        throwsA(
          isA<RequestException>()
              .having((e) => e.code, 'code', isNull)
              .having((e) => e.statusCode, 'status', 422)
              .having((e) => e.errors, 'errors', {
                'items.0.quantity': ['الكمية المطلوبة غير متوفرة'],
              })
              .having((e) => e.details, 'details', isNull),
        ),
      );
    });

    test('an error without a body still throws a request failure', () {
      const response = ApiResponse(statusCode: 500, body: '<html>');

      expect(
        response.ensureOk,
        throwsA(isA<RequestException>()
            .having((e) => e.message, 'message', 'request_failed')),
      );
    });
  });

  group('the mapper keeps the contract code', () {
    test('a refusal naming a field becomes a validation failure', () {
      final failure = mapExceptionToFailure(const RequestException(
        'رمز غير صحيح',
        code: 'coupon_invalid',
        statusCode: 422,
        errors: {'code': 'رمز غير صحيح'},
      ));

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, 'coupon_invalid');
      expect((failure as ValidationFailure)['code'], 'رمز غير صحيح');
    });

    test('a refusal without a field is a server failure with its code', () {
      final failure = mapExceptionToFailure(const RequestException(
        'wrong code',
        code: 'otp_invalid',
        statusCode: 401,
      ));

      expect(failure, isA<ServerFailure>());
      expect(failure.code, 'otp_invalid');
      expect(failure.statusCode, 401);
    });
  });

  group('Money', () {
    test('reads a plain decimal amount as fils', () {
      final money = Money.of(const {'base_price': 4.25}, 'base_price');

      expect(money.fils, 4250);
      expect(money.display, '4.250 د.ك');
    });

    test('reads a decimal amount sent as a string', () {
      final money = Money.of(const {'base_price': '4.250'}, 'base_price');

      expect(money.fils, 4250);
    });

    test('an absent amount is null, not zero', () {
      expect(Money.maybeOf(const {'base_price': 1}, 'compare_price'), isNull);
    });

    test('formats three decimals with Western digits in both languages', () {
      expect(Money.format(13300, 'ar'), '13.300 د.ك');
      expect(Money.format(500, 'en'), '0.500 KWD');
    });
  });

  group('phone', () {
    test('a local number goes out in E.164 with the Kuwaiti code', () {
      expect(toE164('5150 2244'), '+96551502244');
    });

    test('a Kuwaiti number is shown as dial code and two groups', () {
      expect(displayPhone('+96551502244'), '+965 5150 2244');
    });

    test('anything else is shown as it came', () {
      expect(displayPhone('+201064780620'), '+201064780620');
    });
  });
}
