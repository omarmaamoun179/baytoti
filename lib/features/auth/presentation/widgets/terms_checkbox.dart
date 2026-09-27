import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

class TermsCheckbox extends StatelessWidget {
  final bool accepted;
  final bool hasError;
  final VoidCallback onToggle;

  const TermsCheckbox({
    super.key,
    required this.accepted,
    required this.onToggle,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final border = accepted
        ? p.accent
        : hasError
            ? p.danger
            : p.neutral500;

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accepted ? p.accent : Colors.transparent,
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: accepted
                ? AppIcon(
                    AppIcons.check,
                    size: 11,
                    color: p.onAccent,
                    strokeWidth: 3.6,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'auth_terms'.tr(),
              style: AppStrings.w400(11.5, 1.6).c(p.neutral700),
            ),
          ),
        ],
      ),
    );
  }
}
