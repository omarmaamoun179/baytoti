import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/image_ref.dart';

class FamilyProfile extends Equatable {
  final String id;
  final String name;
  final String story;
  final String? city;
  final bool isVerified;
  final ImageRef? cover;
  final ImageRef? avatar;
  final int productCount;
  final double? rating;
  final int followerCount;
  final bool isFollowing;

  const FamilyProfile({
    required this.id,
    required this.name,
    this.story = '',
    this.city,
    this.isVerified = false,
    this.cover,
    this.avatar,
    this.productCount = 0,
    this.rating,
    this.followerCount = 0,
    this.isFollowing = false,
  });

  FamilyProfile withFollowing(bool following) {
    if (following == isFollowing) return this;
    final count = followerCount + (following ? 1 : -1);

    return FamilyProfile(
      id: id,
      name: name,
      story: story,
      city: city,
      isVerified: isVerified,
      cover: cover,
      avatar: avatar,
      productCount: productCount,
      rating: rating,
      followerCount: count < 0 ? 0 : count,
      isFollowing: following,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        story,
        city,
        isVerified,
        cover,
        avatar,
        productCount,
        rating,
        followerCount,
        isFollowing,
      ];
}
