import 'package:equatable/equatable.dart';

class Paged<T> extends Equatable {
  final List<T> items;

  final String? nextCursor;

  final int? total;

  const Paged({this.items = const [], this.nextCursor, this.total});

  bool get hasMore => nextCursor != null;

  bool get isEmpty => items.isEmpty;

  Paged<T> append(Paged<T> next) => Paged<T>(
        items: [...items, ...next.items],
        nextCursor: next.nextCursor,
        total: next.total ?? total,
      );

  @override
  List<Object?> get props => [items, nextCursor, total];
}
