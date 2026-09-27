import '../../../../core/utils/json.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../domain/entities/family_profile.dart';

class FamilyProfileModel extends FamilyProfile {
  const FamilyProfileModel({
    required super.id,
    required super.name,
    super.story,
    super.city,
    super.isVerified,
    super.cover,
    super.avatar,
    super.productCount,
    super.rating,
    super.followerCount,
    super.isFollowing,
  });

  factory FamilyProfileModel.fromJson(Map<String, dynamic> json) {
    final stats = jsonMap(json['stats']);

    return FamilyProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      story: json['story'] as String? ?? '',
      city: json['city'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      cover: ImageRefModel.maybeFrom(json['cover']),
      avatar: ImageRefModel.maybeFrom(json['avatar']),
      productCount: jsonInt(stats['product_count']) ?? 0,
      rating: jsonDouble(stats['rating']),
      followerCount: jsonInt(stats['follower_count']) ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }
}
