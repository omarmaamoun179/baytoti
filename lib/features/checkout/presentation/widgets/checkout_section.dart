import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/section_label.dart';

class CheckoutSection extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  const CheckoutSection({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final actionLabel = this.actionLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: p.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel(label)),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onAction,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    actionLabel,
                    style: AppStrings.w800(11, 1).c(p.accent700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
