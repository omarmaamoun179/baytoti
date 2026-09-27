import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/home_feed.dart';

class ExhibitionBanner extends StatelessWidget {
  final HomeBanner banner;

  const ExhibitionBanner({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = p.onAccent;
    final action = banner.actionLabel;
    final date = banner.dateDisplay;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            banner.kicker,
            size: 9,
            tracking: .2,
            color: ink.withValues(alpha: .85),
          ),
          const SizedBox(height: 10),
          Text(banner.title, style: AppStrings.w800(26, 1.15).c(ink)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              banner.subtitle,
              style: AppStrings.w400(12, 1.6).c(ink.withValues(alpha: .9)),
            ),
          ),
          if (action != null || date != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (action != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: ink.withValues(alpha: .55)),
                    ),
                    child: Text(action, style: AppStrings.w800(11, 1).c(ink)),
                  ),
                if (action != null && date != null) const SizedBox(width: 8),
                if (date != null)
                  Flexible(
                    child: Text(date, style: AppStrings.w800(11, 1).c(ink)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
