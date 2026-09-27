import '../../../../core/utils/json.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../domain/entities/family_profile.dart';

class FamilyProfileModel extends FamilyProfile {
  const FamilyProfileModel({
    required super.id,
    super.slug,
    required super.name,
    super.story,
    super.city,
    super.isVerified,
    super.cover,
    super.avatar,
    super.productCount,
    super.rating,
  });

  factory FamilyProfileModel.fromJson(Map<String, dynamic> json) {
    final id = jsonId(json['id']);
    if (id == null) throw const FormatException('a store without an id');

    return FamilyProfileModel(
      id: id,
      slug: jsonString(json['slug']) ?? id,
      name: jsonString(json['name'])?.trim() ?? '',
      story: jsonString(json['description'])?.trim() ?? '',
      city: jsonString(jsonMap(json['governorate'])['name']) ??
          jsonString(json['city']),
      isVerified:
          jsonBool(json['is_trusted'] ?? json['is_verified']) ?? false,
      cover: ImageRefModel.maybeFrom(json['banner_url'] ?? json['banner']),
      avatar: ImageRefModel.maybeFrom(json['logo_url'] ?? json['logo']),
      productCount: jsonCount(json['products_count'] ?? json['product_count']),
      rating: jsonDouble(json['average_rating'] ?? json['rating']),
    );
  }
}
