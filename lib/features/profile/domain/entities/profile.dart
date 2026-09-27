import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/customer.dart';

class ProfileStats extends Equatable {
  final int orderCount;
  final int favouriteCount;
  final int followingCount;

  const ProfileStats({
    this.orderCount = 0,
    this.favouriteCount = 0,
    this.followingCount = 0,
  });

  int get favouritesAndFollowing => favouriteCount + followingCount;

  @override
  List<Object?> get props => [orderCount, favouriteCount, followingCount];
}

class Profile extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String? language;
  final ProfileStats stats;

  const Profile({
    required this.id,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.language,
    this.stats = const ProfileStats(),
  });

  Customer get customer => Customer(
        id: id,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );

  @override
  List<Object?> get props => [id, fullName, phone, avatarUrl, language, stats];
}
