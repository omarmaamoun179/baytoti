import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

class ProfileRow extends StatelessWidget {
  final String label;
  final String? meta;
  final VoidCallback onTap;
  final bool isSignOut;

  const ProfileRow({
    super.key,
    required this.label,
    this.meta,
    required this.onTap,
    this.isSignOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: p.hairline)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppStrings.w600(13, 1.2).c(
                  isSignOut ? p.accent700 : p.text,
                ),
              ),
            ),
            if (meta != null && meta!.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(meta!, style: AppStrings.w400(11, 1).c(p.neutral600)),
            ],
            const SizedBox(width: 12),
            AppIcon(
              AppIcons.forward,
              size: 13,
              color: p.neutral500,
              strokeWidth: 2.2,
            ),
          ],
        ),
      ),
    );
  }
}
