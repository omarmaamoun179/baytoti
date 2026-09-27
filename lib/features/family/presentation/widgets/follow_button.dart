import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

class FollowButton extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;

  const FollowButton({super.key, required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(10);

    return Semantics(
      button: true,
      selected: following,
      child: Material(
        color: following ? p.surface : p.accent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            child: Text(
              following ? 'family_following'.tr() : 'family_follow'.tr(),
              style: AppStrings.w800(12, 1).c(following ? p.text : p.onAccent),
            ),
          ),
        ),
      ),
    );
  }
}
