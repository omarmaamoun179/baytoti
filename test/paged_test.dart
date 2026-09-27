import 'package:baytoti/core/domain/paged.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Paged', () {
    test('another page exists only while there is a cursor', () {
      expect(const Paged<int>(items: [1, 2], nextCursor: 'abc').hasMore, isTrue);
      expect(const Paged<int>(items: [1, 2]).hasMore, isFalse);
    });

    test('a short page with a cursor is not the last one', () {
      const page = Paged<int>(items: [1], nextCursor: 'next');

      expect(page.hasMore, isTrue);
    });

    test('appending keeps the rows in order and takes the new cursor', () {
      const first = Paged<int>(items: [1, 2], nextCursor: 'b', total: 4);
      const second = Paged<int>(items: [3, 4]);

      final merged = first.append(second);

      expect(merged.items, [1, 2, 3, 4]);
      expect(merged.nextCursor, isNull);
      expect(merged.hasMore, isFalse);
      expect(merged.total, 4);
    });
  });
}
