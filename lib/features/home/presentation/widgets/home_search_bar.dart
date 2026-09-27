import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const HomeSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(12);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: p.rule)),
      child: Material(
        color: p.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: p.divider),
            ),
            child: Row(
              children: [
                AppIcon(AppIcons.search, size: 15, color: p.neutral700),
                const SizedBox(width: 10),
                Text(
                  'search_placeholder'.tr(),
                  style: AppStrings.w400(13, 1).c(p.neutral700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
