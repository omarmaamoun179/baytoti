import '../../../../core/utils/json.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/product_badge.dart';
import '../../domain/entities/product_detail.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    super.authorId,
    required super.authorName,
    required super.rating,
    required super.body,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = jsonMap(json['user']);

    return ReviewModel(
      id: jsonId(json['id']) ?? '',
      authorId: jsonId(user['id'] ?? json['user_id']),
      authorName:
          jsonString(user['name'] ?? json['author_name'])?.trim() ?? '',
      rating: jsonCount(json['rating']) ?? 0,
      body: jsonString(json['comment'] ?? json['body'])?.trim() ?? '',
    );
  }

  static List<Review> listFrom(Object? value) =>
      [for (final item in jsonList(value)) ReviewModel.fromJson(item)];
}

class ProductDetailModel extends ProductDetail {
  const ProductDetailModel({
    required super.id,
    super.slug,
    required super.name,
    super.description,
    required super.price,
    super.compareAt,
    super.badge,
    super.rating,
    super.soldCount,
    super.stock,
    super.inStock,
    super.preparationMinutes,
    super.fulfilment,
    super.maxPerOrder,
    super.images,
    required super.family,
    super.isFavourite,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final id = jsonId(json['id']);
    if (id == null) throw const FormatException('a product without an id');

    final (price, compareAt) = PriceModel.read(json);
    final stock = jsonCount(json['stock'] ?? json['stock_quantity']);
    final featured = jsonBool(json['is_featured']) ?? false;

    return ProductDetailModel(
      id: id,
      slug: jsonString(json['slug']) ?? id,
      name: jsonString(json['name']) ?? '',
      description: _description(json),
      price: price,
      compareAt: compareAt,
      badge: ProductBadge.fromWire(json['badge']) ??
          (featured ? ProductBadge.featured : null),
      rating: jsonDouble(json['average_rating'] ?? json['rating']),
      soldCount: jsonCount(json['sold_count'] ?? json['sales_count']),
      stock: stock,
      inStock: jsonBool(json['is_available'] ?? json['in_stock']) ??
          (stock == null || stock > 0),
      preparationMinutes: jsonCount(json['preparation_time_minutes']),
      fulfilment: {
        for (final wire in stringList(json['fulfilment']))
          ?Fulfilment.fromWire(wire),
      },
      maxPerOrder: jsonCount(json['max_per_order']),
      images: _images(json),
      family: FamilyRefModel.fromJson(jsonMap(json['store'] ?? json['family'])),
      isFavourite: jsonBool(
            json['is_favorite'] ??
                json['is_favourite'] ??
                json['is_wishlisted'] ??
                json['in_wishlist'],
          ) ??
          false,
    );
  }

  static String _description(Map<String, dynamic> json) {
    final full = jsonString(json['description'])?.trim() ?? '';
    if (full.isNotEmpty) return full;
    return jsonString(json['short_description'])?.trim() ?? '';
  }

  static List<ImageRef> _images(Map<String, dynamic> json) {
    final images = ImageRefModel.listFrom(json['images']);
    if (images.isNotEmpty) return images;
    return [?ImageRefModel.maybeFrom(json['thumbnail'])];
  }
}
