import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'family_ref.dart';
import 'image_ref.dart';
import 'product_badge.dart';

class ProductSummary extends Equatable {
  final String id;
  final String name;
  final FamilyRef family;
  final Money price;
  final Money? compareAt;
  final ProductBadge? badge;
  final double? rating;
  final bool inStock;
  final List<ImageRef> images;
  final bool isFavourite;

  const ProductSummary({
    required this.id,
    required this.name,
    required this.family,
    required this.price,
    this.compareAt,
    this.badge,
    this.rating,
    this.inStock = true,
    this.images = const [],
    this.isFavourite = false,
  });

  ProductSummary copyWith({bool? isFavourite}) => ProductSummary(
        id: id,
        name: name,
        family: family,
        price: price,
        compareAt: compareAt,
        badge: badge,
        rating: rating,
        inStock: inStock,
        images: images,
        isFavourite: isFavourite ?? this.isFavourite,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        family,
        price,
        compareAt,
        badge,
        rating,
        inStock,
        images,
        isFavourite,
      ];
}
