import 'package:equatable/equatable.dart';

enum CategoryIcon {
  sweets(
    'M12 3c3 2.6 4.5 5 4.5 7.2A4.5 4.5 0 0112 15a4.5 4.5 0 01-4.5-4.8C7.5 8 9 5.6 12 3M4 19h16M6 21h12',
    tinted: false,
  ),
  bakery('M4 13c0-4 3.6-7 8-7s8 3 8 7M3 16h18M5 19h14', tinted: true),
  spices('M9 3h6v3H9zM8 6h8l1.4 12.5a2 2 0 01-2 2.5H8.6a2 2 0 01-2-2.5zM9 12h6', tinted: false),
  crafts('M4 20l6-6M7 17l-3 3M12.5 11.5L20 4M16 4h4v4M9 9l6 6', tinted: true),
  perfume('M10 3h4v3h-4zM8.5 6h7l1 4.5a5 5 0 11-9 0zM12 13v4', tinted: false),
  savoury('M12 4a8 8 0 018 8H4a8 8 0 018-8zM3 15h18M5 18h14', tinted: true);

  final String path;
  final bool tinted;

  const CategoryIcon(this.path, {required this.tinted});

  static CategoryIcon fromWire(Object? value) {
    for (final icon in values) {
      if (icon.name == value) return icon;
    }
    return sweets;
  }
}

class Category extends Equatable {
  final String id;
  final String slug;
  final String name;
  final CategoryIcon icon;
  final String? imageUrl;
  final int productCount;

  const Category({
    required this.id,
    String? slug,
    required this.name,
    required this.icon,
    this.imageUrl,
    this.productCount = 0,
  }) : slug = slug ?? id;

  @override
  List<Object?> get props => [id, slug, name, icon, imageUrl, productCount];
}
