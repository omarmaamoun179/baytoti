import 'package:equatable/equatable.dart';

class Paged<T> extends Equatable {
  final List<T> items;

  final int currentPage;

  final int lastPage;

  final int? total;

  const Paged({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total,
  });

  factory Paged.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = json['data'];
    final items = <T>[
      if (data is List)
        for (final item in data)
          fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};

    return Paged(
      items: items,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt(),
    );
  }

  int get nextPage => currentPage + 1;

  bool get hasMore => currentPage < lastPage;

  bool get isEmpty => items.isEmpty;

  Paged<T> append(Paged<T> next) => Paged<T>(
        items: [...items, ...next.items],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total ?? total,
      );

  @override
  List<Object?> get props => [items, currentPage, lastPage, total];
}
