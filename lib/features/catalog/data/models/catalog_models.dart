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

  static const List<String> _urlKeys = ['url', 'image', 'image_url', 'path'];

  static ImageRef? maybeFrom(Object? value) {
    if (value is String) return value.isEmpty ? null : ImageRefModel(url: value);
    final json = jsonMapOrNull(value);
    if (json == null) return null;

    for (final key in _urlKeys) {
      final url = jsonString(json[key]);
      if (url != null && url.isNotEmpty) {
        return ImageRefModel(
          url: url,
          width: jsonInt(json['width']),
          height: jsonInt(json['height']),
          alt: jsonString(json['alt'] ?? json['alt_text']) ?? '',
        );
      }
    }
    return null;
  }

  static List<ImageRef> listFrom(Object? value) => [
        if (value is List)
          for (final item in value) ?maybeFrom(item),
      ];
}

class FamilyRefModel extends FamilyRef {
  const FamilyRefModel({
    required super.id,
    super.slug,
    required super.name,
    super.city,
    super.rating,
    super.productCount,
    super.isVerified,
    super.images,
  });

  factory FamilyRefModel.fromJson(Map<String, dynamic> json) {
    final id = jsonId(json['id']) ?? '';
    final logo = ImageRefModel.maybeFrom(json['logo_url'] ?? json['logo']);

    return FamilyRefModel(
      id: id,
      slug: jsonString(json['slug']) ?? id,
      name: jsonString(json['name']) ?? '',
      city: jsonString(jsonMap(json['governorate'])['name']) ??
          jsonString(json['city']),
      rating: jsonDouble(json['rating'] ?? json['average_rating']),
      productCount: jsonCount(json['products_count'] ?? json['product_count']),
      isVerified: jsonBool(
            json['is_trusted'] ?? json['is_verified'] ?? json['is_approved'],
          ) ??
          false,
      images: [
        ?logo,
        ...ImageRefModel.listFrom(json['images']),
      ],
    );
  }
}

class PriceModel {
  static (Money, Money?) read(Map<String, dynamic> json) {
    final price = jsonMapOrNull(json['price']);
    final current = Money.parse(
          price?['current'] ?? json['base_price'] ?? json['price'],
        ) ??
        const Money(fils: 0);
    final original = Money.parse(
      price?['original'] ?? json['compare_price'] ?? json['compare_at'],
    );

    return (
      current,
      original != null && original.fils > current.fils ? original : null,
    );
  }
}

class ProductSummaryModel extends ProductSummary {
  const ProductSummaryModel({
    required super.id,
    super.slug,
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

  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    final id = jsonId(json['id']) ?? '';
    final (price, compareAt) = PriceModel.read(json);
    final featured = jsonBool(json['is_featured']) ?? false;

    return ProductSummaryModel(
      id: id,
      slug: jsonString(json['slug']) ?? id,
      name: jsonString(json['name']) ?? '',
      family: FamilyRefModel.fromJson(jsonMap(json['store'] ?? json['family'])),
      price: price,
      compareAt: compareAt,
      badge: ProductBadge.fromWire(json['badge']) ??
          (featured ? ProductBadge.featured : null),
      rating: jsonDouble(json['rating'] ?? json['average_rating']),
      inStock: jsonBool(json['is_available'] ?? json['in_stock']) ?? true,
      images: [
        ?ImageRefModel.maybeFrom(json['thumbnail']),
        ...ImageRefModel.listFrom(json['images']),
      ],
      isFavourite: jsonBool(
            json['is_favorite'] ??
                json['is_favourite'] ??
                json['is_wishlisted'] ??
                json['in_wishlist'],
          ) ??
          false,
    );
  }

  static List<ProductSummary> listFrom(Object? value) =>
      [for (final item in jsonList(value)) ProductSummaryModel.fromJson(item)];

  static Paged<ProductSummary> pageFrom(Map<String, dynamic> json) =>
      Paged.fromJson(json, ProductSummaryModel.fromJson);
}

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    super.slug,
    required super.name,
    required super.icon,
    super.imageUrl,
    super.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final id = jsonId(json['id']) ?? '';

    return CategoryModel(
      id: id,
      slug: jsonString(json['slug']) ?? id,
      name: jsonString(json['name']) ?? '',
      icon: CategoryIcon.fromWire(json['icon']),
      imageUrl: jsonString(json['image_url'] ?? json['image']),
      productCount:
          jsonCount(json['products_count'] ?? json['product_count']) ?? 0,
    );
  }

  static List<Category> listFrom(Object? value) =>
      [for (final item in jsonList(value)) CategoryModel.fromJson(item)];
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
        subtotal: Money.parse(json['subtotal']) ?? const Money(fils: 0),
        discount: Money.parse(
              json['discount'] ?? json['discount_total'] ?? json['discount_amount'],
            ) ??
            const Money(fils: 0),
        shipping: Money.parse(
              json['shipping'] ?? json['shipping_total'] ?? json['delivery_fee'],
            ) ??
            const Money(fils: 0),
        total: Money.parse(json['total'] ?? json['grand_total']) ??
            const Money(fils: 0),
      );
}
