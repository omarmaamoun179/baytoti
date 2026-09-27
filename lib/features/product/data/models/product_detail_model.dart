import '../../../../core/utils/json.dart';
import '../../../../core/utils/money.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/domain/entities/product_badge.dart';
import '../../domain/entities/product_detail.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.authorName,
    required super.rating,
    required super.body,
    super.createdDisplay,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        authorName: json['author_name'] as String? ?? '',
        rating: jsonInt(json['rating']) ?? 0,
        body: json['body'] as String? ?? '',
        createdDisplay: json['created_display'] as String? ?? '',
      );

  static List<Review> listFrom(Object? value) =>
      [for (final item in jsonList(value)) ReviewModel.fromJson(item)];
}

class ProductDetailModel extends ProductDetail {
  const ProductDetailModel({
    required super.id,
    required super.name,
    super.description,
    required super.price,
    super.compareAt,
    super.badge,
    super.rating,
    super.ratingCount,
    super.soldCount,
    required super.stock,
    required super.inStock,
    super.preparationTime,
    super.fulfilment,
    required super.maxPerOrder,
    super.images,
    required super.family,
    super.familyAvatar,
    super.isFavourite,
    super.reviews,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final family = jsonMap(json['family']);
    final stock = jsonInt(json['stock']) ?? 0;

    return ProductDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: Money.of(json, 'price'),
      compareAt: Money.maybeOf(json, 'compare_at'),
      badge: ProductBadge.fromWire(json['badge']),
      rating: jsonDouble(json['rating']),
      ratingCount: jsonInt(json['rating_count']) ?? 0,
      soldCount: jsonInt(json['sold_count']) ?? 0,
      stock: stock,
      inStock: json['in_stock'] as bool? ?? stock > 0,
      preparationTime: json['preparation_time_display'] as String? ?? '',
      fulfilment: {
        for (final wire in stringList(json['fulfilment']))
          ?Fulfilment.fromWire(wire),
      },
      maxPerOrder: jsonInt(json['max_per_order']) ?? stock,
      images: ImageRefModel.listFrom(json['images']),
      family: FamilyRefModel.fromJson(family),
      familyAvatar: ImageRefModel.maybeFrom(family['avatar']),
      isFavourite: json['is_favourite'] as bool? ?? false,
      reviews: ReviewModel.listFrom(json['reviews_preview']),
    );
  }
}
