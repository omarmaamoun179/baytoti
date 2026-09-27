import 'package:baytoti/core/utils/validators/validator_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateTextLength', () {
    test('an empty text passes only when it may be left out', () {
      expect(validateTextLength('  ', maxLength: 10), isNull);
      expect(
        validateTextLength('  ', maxLength: 10, isRequired: true),
        'field_required',
      );
    });

    test('holds the text to both ends of the limit, once trimmed', () {
      expect(validateTextLength(' a ', minLength: 2, maxLength: 3),
          'text_too_short');
      expect(validateTextLength(' ab ', minLength: 2, maxLength: 3), isNull);
      expect(validateTextLength('abc', minLength: 2, maxLength: 3), isNull);
      expect(validateTextLength('abcd', minLength: 2, maxLength: 3),
          'text_too_long');
    });

    test('counts Arabic letter by letter', () {
      expect(validateTextLength('دار لمى', maxLength: 7), isNull);
      expect(validateTextLength('دار لمى!', maxLength: 7), 'text_too_long');
    });

    test('counts code points, as the server does', () {
      const thumbsUp = '👍🏽';

      expect(validateTextLength(thumbsUp, maxLength: 2), isNull);
      expect(validateTextLength(thumbsUp, maxLength: 1), 'text_too_long');
    });
  });
}
