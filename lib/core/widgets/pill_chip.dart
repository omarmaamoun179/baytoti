import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 13),
  });

  const PillChip.tag({super.key, required this.label})
      : selected = false,
        onTap = null,
        padding = const EdgeInsets.symmetric(vertical: 7, horizontal: 12);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(999);

    return Material(
      color: selected ? p.accent : p.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: selected ? p.accent : p.divider),
          ),
          child: Text(
            label,
            style: AppStrings.w600(11, 1).c(
              selected
                  ? p.onAccent
                  : onTap == null
                      ? p.neutral800
                      : p.text,
            ),
          ),
        ),
      ),
    );
  }
}

class ChipStrip extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const ChipStrip({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: context.palette.hairline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
