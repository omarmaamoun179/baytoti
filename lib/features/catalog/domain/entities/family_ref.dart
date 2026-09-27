import 'package:equatable/equatable.dart';

import 'image_ref.dart';

class FamilyRef extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? city;
  final double? rating;
  final int? productCount;
  final bool isVerified;
  final List<ImageRef> images;

  const FamilyRef({
    required this.id,
    String? slug,
    required this.name,
    this.city,
    this.rating,
    this.productCount,
    this.isVerified = false,
    this.images = const [],
  }) : slug = slug ?? id;

  @override
  List<Object?> get props =>
      [id, slug, name, city, rating, productCount, isVerified, images];
}
