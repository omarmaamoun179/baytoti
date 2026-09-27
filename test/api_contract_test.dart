import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/domain/failure_mapper.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_response.dart';
import 'package:baytoti/core/utils/market.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/phone.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

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

    test('a server error without a body is a generic server failure', () {
      const response = ApiResponse(statusCode: 500, body: '<html>');

      expect(
        response.ensureOk,
        throwsA(isA<RequestException>()
            .having((e) => e.message, 'message', 'server_error')),
      );
    });

    test('a server crash never shows its exception text', () {
      final response = ApiResponse(
        statusCode: 500,
        body: apiSample('betouti/products_guest_500.json'),
      );

      expect(
        response.ensureOk,
        throwsA(isA<RequestException>()
            .having((e) => e.message, 'message', 'server_error')
            .having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('an unauthenticated call carries the bare Laravel message', () {
      final response = ApiResponse(
        statusCode: 401,
        body: apiSample('betouti/unauthenticated_401.json'),
      );

      expect(
        response.ensureOk,
        throwsA(isA<RequestException>()
            .having((e) => e.message, 'message', 'Unauthenticated.')
            .having((e) => e.statusCode, 'status', 401)),
      );
    });

    test('the live register validation reads as field errors', () {
      final response = ApiResponse(
        statusCode: 422,
        body: apiSample('betouti/auth_register_422.json'),
      );

      expect(
        response.ensureOk,
        throwsA(isA<RequestException>().having(
          (e) => e.errors?.keys,
          'fields',
          containsAll(['name', 'email', 'password']),
        )),
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
    setUp(() {
      Money.languageCode = 'ar';
      Money.market = Market.kw;
    });

    tearDown(() {
      Money.languageCode = 'ar';
      Money.market = Market.kw;
    });

    test('reads a plain decimal amount as fils', () {
      final money = Money.of(const {'base_price': 4.25}, 'base_price');

      expect(money.fils, 4250);
      expect(money.display, '4.250 د.ك');
    });

    test('reads a decimal amount sent as a string', () {
      final money = Money.of(const {'price': '55.000'}, 'price');

      expect(money.fils, 55000);
    });

    test('an absent amount is null, not zero', () {
      expect(Money.maybeOf(const {'base_price': 1}, 'compare_price'), isNull);
    });

    test('follows the current language', () {
      Money.languageCode = 'en';

      expect(const Money(fils: 500).display, '0.500 KWD');
    });

    test('an Egyptian market shows two decimals in pounds', () {
      Money.market = Market.eg;

      expect(Money.format(13300, 'ar'), '13.30 ج.م');
      expect(Money.format(500, 'en'), '0.50 EGP');
    });

    test('a Kuwaiti market shows three decimals in dinars', () {
      expect(Money.format(13300, 'ar'), '13.300 د.ك');
      expect(Money.format(500, 'en'), '0.500 KWD');
    });
  });

  group('phone', () {
    test('goes out as digits with the country code', () {
      expect(wirePhone('+965 5150 2244'), '96551502244');
      expect(wirePhone('+20 106 478 0620'), '201064780620');
    });

    test('a Kuwaiti number is shown as dial code and two groups', () {
      expect(displayPhone('+96551502244'), '+965 5150 2244');
    });

    test('an unknown number is shown as it came', () {
      expect(displayPhone('+441234567890'), '+441234567890');
    });
  });
}
