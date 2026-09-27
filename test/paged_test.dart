import 'package:baytoti/core/domain/paged.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Paged', () {
    test('another page exists only while the current page trails the last', () {
      expect(
        const Paged<int>(items: [1, 2], currentPage: 1, lastPage: 2).hasMore,
        isTrue,
      );
      expect(const Paged<int>(items: [1, 2]).hasMore, isFalse);
    });

    test('a short page short of the last page is not the last one', () {
      const page = Paged<int>(items: [1], currentPage: 1, lastPage: 2);

      expect(page.hasMore, isTrue);
    });

    test('appending keeps the rows in order and takes the new page', () {
      const first =
          Paged<int>(items: [1, 2], currentPage: 1, lastPage: 2, total: 4);
      const second = Paged<int>(items: [3, 4], currentPage: 2, lastPage: 2);

      final merged = first.append(second);

      expect(merged.items, [1, 2, 3, 4]);
      expect(merged.currentPage, 2);
      expect(merged.hasMore, isFalse);
      expect(merged.total, 4);
    });
  });
}
