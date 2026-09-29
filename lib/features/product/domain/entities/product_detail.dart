import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/product_badge.dart';

enum Fulfilment {
  delivery('delivery'),
  pickup('pickup');

  final String wire;

  const Fulfilment(this.wire);

  static Fulfilment? fromWire(Object? value) {
    for (final method in values) {
      if (method.wire == value) return method;
    }
    return null;
  }
}

class Review extends Equatable {
  static const int maxRating = 5;

  final String id;
  final String? authorId;
  final String authorName;
  final int rating;
  final String body;

  const Review({
    required this.id,
    this.authorId,
    required this.authorName,
    required this.rating,
    required this.body,
  });

  String get stars {
    final filled = rating.clamp(0, maxRating);
    return '${'★' * filled}${'☆' * (maxRating - filled)}';
  }

  @override
  List<Object?> get props => [id, authorId, authorName, rating, body];
}

class ReviewsQuery extends Equatable {
  final String productId;
  final String? authorId;

  const ReviewsQuery({required this.productId, this.authorId});

  @override
  List<Object?> get props => [productId, authorId];
}

class ReviewDigest extends Equatable {
  final List<Review> latest;
  final Review? mine;

  const ReviewDigest({this.latest = const [], this.mine});

  @override
  List<Object?> get props => [latest, mine];
}

class ProductDetail extends Equatable {
  static const int quantityCeiling = 99;

  final String id;
  final String slug;
  final String name;
  final String description;
  final Money price;
  final Money? compareAt;
  final ProductBadge? badge;
  final double? rating;
  final int? soldCount;
  final int? stock;
  final bool inStock;
  final int? preparationMinutes;
  final Set<Fulfilment> fulfilment;
  final int? maxPerOrder;
  final List<ImageRef> images;
  final FamilyRef family;
  final bool isFavourite;

  const ProductDetail({
    required this.id,
    String? slug,
    required this.name,
    this.description = '',
    required this.price,
    this.compareAt,
    this.badge,
    this.rating,
    this.soldCount,
    this.stock,
    this.inStock = true,
    this.preparationMinutes,
    this.fulfilment = const {},
    this.maxPerOrder,
    this.images = const [],
    required this.family,
    this.isFavourite = false,
  }) : slug = slug ?? id;

  int get maxQuantity {
    if (!inStock) return 0;
    final limits = [?stock, ?maxPerOrder, quantityCeiling];
    return math.max(0, limits.reduce(math.min));
  }

  bool get canOrder => maxQuantity > 0;

  ProductDetail copyWith({bool? isFavourite}) => ProductDetail(
        id: id,
        slug: slug,
        name: name,
        description: description,
        price: price,
        compareAt: compareAt,
        badge: badge,
        rating: rating,
        soldCount: soldCount,
        stock: stock,
        inStock: inStock,
        preparationMinutes: preparationMinutes,
        fulfilment: fulfilment,
        maxPerOrder: maxPerOrder,
        images: images,
        family: family,
        isFavourite: isFavourite ?? this.isFavourite,
      );

  @override
  List<Object?> get props => [
        id,
        slug,
        name,
        description,
        price,
        compareAt,
        badge,
        rating,
        soldCount,
        stock,
        inStock,
        preparationMinutes,
        fulfilment,
        maxPerOrder,
        images,
        family,
        isFavourite,
      ];
}
