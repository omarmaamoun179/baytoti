import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

final RegExp _arabic = RegExp(r'[؀-ۿ]');

class SectionLabel extends StatelessWidget {
  final String text;
  final double size;
  final double tracking;
  final Color? color;

  const SectionLabel(
    this.text, {
    super.key,
    this.size = 10,
    this.tracking = .14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final latin = !_arabic.hasMatch(text);
    final style = AppStrings.w800(size, 1).c(color ?? context.palette.neutral700);

    return Text(
      latin ? text.toUpperCase() : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: latin ? style.spaced(size * tracking) : style,
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? caption;

  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(title, style: AppStrings.w800(17, 1.2).c(p.text)),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                actionLabel!,
                style: AppStrings.w800(11, 1).c(p.accent700),
              ),
            ),
          ),
        if (caption != null)
          Text(caption!, style: AppStrings.w400(11, 1).c(p.neutral600)),
      ],
    );
  }
}
