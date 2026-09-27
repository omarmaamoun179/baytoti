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
  final String authorName;
  final int rating;
  final String body;
  final String createdDisplay;

  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.body,
    this.createdDisplay = '',
  });

  String get stars {
    final filled = rating.clamp(0, maxRating);
    return '${'★' * filled}${'☆' * (maxRating - filled)}';
  }

  @override
  List<Object?> get props => [id, authorName, rating, body, createdDisplay];
}

class ProductDetail extends Equatable {
  final String id;
  final String name;
  final String description;
  final Money price;
  final Money? compareAt;
  final ProductBadge? badge;
  final double? rating;
  final int ratingCount;
  final int soldCount;
  final int stock;
  final bool inStock;
  final String preparationTime;
  final Set<Fulfilment> fulfilment;
  final int maxPerOrder;
  final List<ImageRef> images;
  final FamilyRef family;
  final ImageRef? familyAvatar;
  final bool isFavourite;
  final List<Review> reviews;

  const ProductDetail({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.compareAt,
    this.badge,
    this.rating,
    this.ratingCount = 0,
    this.soldCount = 0,
    required this.stock,
    required this.inStock,
    this.preparationTime = '',
    this.fulfilment = const {},
    required this.maxPerOrder,
    this.images = const [],
    required this.family,
    this.familyAvatar,
    this.isFavourite = false,
    this.reviews = const [],
  });

  int get maxQuantity => inStock ? math.max(0, math.min(maxPerOrder, stock)) : 0;

  bool get canOrder => maxQuantity > 0;

  ProductDetail copyWith({bool? isFavourite}) => ProductDetail(
        id: id,
        name: name,
        description: description,
        price: price,
        compareAt: compareAt,
        badge: badge,
        rating: rating,
        ratingCount: ratingCount,
        soldCount: soldCount,
        stock: stock,
        inStock: inStock,
        preparationTime: preparationTime,
        fulfilment: fulfilment,
        maxPerOrder: maxPerOrder,
        images: images,
        family: family,
        familyAvatar: familyAvatar,
        isFavourite: isFavourite ?? this.isFavourite,
        reviews: reviews,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        compareAt,
        badge,
        rating,
        ratingCount,
        soldCount,
        stock,
        inStock,
        preparationTime,
        fulfilment,
        maxPerOrder,
        images,
        family,
        familyAvatar,
        isFavourite,
        reviews,
      ];
}
