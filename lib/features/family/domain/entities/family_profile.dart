import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/image_ref.dart';

class FamilyProfile extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String story;
  final String? city;
  final bool isVerified;
  final ImageRef? cover;
  final ImageRef? avatar;
  final int? productCount;
  final double? rating;

  const FamilyProfile({
    required this.id,
    String? slug,
    required this.name,
    this.story = '',
    this.city,
    this.isVerified = false,
    this.cover,
    this.avatar,
    this.productCount,
    this.rating,
  }) : slug = slug ?? id;

  @override
  List<Object?> get props => [
        id,
        slug,
        name,
        story,
        city,
        isVerified,
        cover,
        avatar,
        productCount,
        rating,
      ];
}
