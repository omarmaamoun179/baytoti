import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../domain/entities/family_profile.dart';
import 'follow_button.dart';

class FamilyHeader extends StatelessWidget {
  static const double coverHeight = 128;
  static const double avatarSize = 62;
  static const double avatarLift = 38;

  final FamilyProfile family;
  final VoidCallback onFollow;

  const FamilyHeader({super.key, required this.family, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final meta = [
      ?family.city,
      if (family.isVerified) 'family_verified'.tr(),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: coverHeight,
          child: NetworkPhoto(
            url: family.cover?.url,
            placeholderColor: p.neutral400,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(bottom: p.rule)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.name,
                          style: AppStrings.w800(20, 1.2).c(p.text),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            meta,
                            style: AppStrings.w400(12, 1.5).c(p.neutral700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FollowButton(
                    following: family.isFollowing,
                    onTap: onFollow,
                  ),
                ],
              ),
              if (family.story.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  family.story,
                  style: AppStrings.w400(13, 1.75).c(p.neutral800),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final p = context.palette;

    return SizedBox(
      width: avatarSize,
      height: avatarSize - avatarLift,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -avatarLift,
            left: 0,
            right: 0,
            height: avatarSize,
            child: Container(
              decoration: BoxDecoration(
                color: p.neutral300,
                border: Border.all(color: p.bg, width: 2),
              ),
              child: NetworkPhoto(url: family.avatar?.url),
            ),
          ),
        ],
      ),
    );
  }
}
