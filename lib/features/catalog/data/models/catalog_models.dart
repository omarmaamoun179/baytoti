import '../../../../core/domain/paged.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/family_ref.dart';
import '../../domain/entities/image_ref.dart';
import '../../domain/entities/order_totals.dart';
import '../../domain/entities/product_badge.dart';
import '../../domain/entities/product_summary.dart';

class ImageRefModel extends ImageRef {
  const ImageRefModel({
    required super.url,
    super.width,
    super.height,
    super.alt,
  });

  factory ImageRefModel.fromJson(Map<String, dynamic> json) => ImageRefModel(
        url: json['url'] as String,
        width: jsonInt(json['width']),
        height: jsonInt(json['height']),
        alt: json['alt'] as String? ?? '',
      );

  static List<ImageRef> listFrom(Object? value) =>
      [for (final image in jsonList(value)) ImageRefModel.fromJson(image)];

  static ImageRef? maybeFrom(Object? value) {
    final json = jsonMapOrNull(value);
    return json == null ? null : ImageRefModel.fromJson(json);
  }
}

class FamilyRefModel extends FamilyRef {
  const FamilyRefModel({
    required super.id,
    required super.name,
    super.city,
    super.rating,
    super.productCount,
    super.isVerified,
    super.images,
  });

  factory FamilyRefModel.fromJson(Map<String, dynamic> json) => FamilyRefModel(
        id: json['id'] as String,
        name: json['name'] as String,
        city: json['city'] as String?,
        rating: jsonDouble(json['rating']),
        productCount: jsonInt(json['product_count']),
        isVerified: json['is_verified'] as bool? ?? false,
        images: ImageRefModel.listFrom(json['images']),
      );
}

class ProductSummaryModel extends ProductSummary {
  const ProductSummaryModel({
    required super.id,
    required super.name,
    required super.family,
    required super.price,
    super.compareAt,
    super.badge,
    super.rating,
    super.inStock,
    super.images,
    super.isFavourite,
  });

  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) =>
      ProductSummaryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        family: FamilyRefModel.fromJson(jsonMap(json['family'])),
        price: Money.of(json, 'price'),
        compareAt: Money.maybeOf(json, 'compare_at'),
        badge: ProductBadge.fromWire(json['badge']),
        rating: jsonDouble(json['rating']),
        inStock: json['in_stock'] as bool? ?? true,
        images: ImageRefModel.listFrom(json['images']),
        isFavourite: json['is_favourite'] as bool? ?? false,
      );

  static List<ProductSummary> listFrom(Object? value) =>
      [for (final item in jsonList(value)) ProductSummaryModel.fromJson(item)];

  static Paged<ProductSummary> pageFrom(Map<String, dynamic> json) =>
      Paged<ProductSummary>(
        items: listFrom(json['items']),
        nextCursor: json['next_cursor'] as String?,
        total: jsonInt(json['total']),
      );
}

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    super.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: CategoryIcon.fromWire(json['icon']),
        productCount: jsonInt(json['product_count']) ?? 0,
      );
}

class OrderTotalsModel extends OrderTotals {
  const OrderTotalsModel({
    required super.subtotal,
    required super.discount,
    required super.shipping,
    required super.total,
  });

  factory OrderTotalsModel.fromJson(Map<String, dynamic> json) =>
      OrderTotalsModel(
        subtotal: Money.of(json, 'subtotal'),
        discount: Money.of(json, 'discount'),
        shipping: Money.of(json, 'shipping'),
        total: Money.of(json, 'total'),
      );
}
