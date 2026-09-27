import '../../../../core/utils/json.dart';
import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.fullName,
    required super.phone,
    super.avatarUrl,
    super.language,
    super.stats,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final stats = jsonMap(json['stats']);

    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: switch (json['avatar']) {
        final String url => url,
        final Map<dynamic, dynamic> image => image['url'] as String?,
        _ => null,
      },
      language: json['language'] as String?,
      stats: ProfileStats(
        orderCount: jsonInt(stats['order_count']) ?? 0,
        favouriteCount: jsonInt(stats['favourite_count']) ?? 0,
        followingCount: jsonInt(stats['following_count']) ?? 0,
      ),
    );
  }
}
