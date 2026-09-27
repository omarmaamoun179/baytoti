import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

class AddressDefaultToggle extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;

  const AddressDefaultToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      checked: value,
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? p.accent : Colors.transparent,
                border: Border.all(
                  color: value ? p.accent : p.neutral500,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: value
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
              child: Text(label, style: AppStrings.w600(12.5, 1.5).c(p.text)),
            ),
          ],
        ),
      ),
    );
  }
}
