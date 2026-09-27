import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/section_label.dart';

class OrderHeaderCard extends StatelessWidget {
  final String reference;
  final String? subtitle;

  const OrderHeaderCard({super.key, required this.reference, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final subtitle = this.subtitle;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            'order_number'.tr(),
            size: 9,
            tracking: .18,
            color: p.onAccent.withValues(alpha: .7),
          ),
          const SizedBox(height: 7),
          Text(reference, style: AppStrings.w800(22, 1.2).c(p.onAccent)),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppStrings.w400(12, 1.5)
                  .c(p.onAccent.withValues(alpha: .8)),
            ),
          ],
        ],
      ),
    );
  }
}
