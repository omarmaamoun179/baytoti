import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';

enum AppButtonStyle { primary, outline, quiet, light, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool pill;
  final double height;
  final double fontSize;
  final String? trailingText;
  final AppIconData? trailingIcon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.pill = false,
    this.height = 52,
    this.fontSize = 14,
    this.trailingText,
    this.trailingIcon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !isLoading;

    final (background, foreground, border) = switch (style) {
      AppButtonStyle.primary => (
          enabled || isLoading ? p.accent : p.neutral500,
          p.onAccent,
          null,
        ),
      AppButtonStyle.outline => (
          p.surface,
          p.accent,
          Border.all(color: p.accent, width: 1.5),
        ),
      AppButtonStyle.quiet => (
          Colors.transparent,
          p.text,
          Border.all(color: p.divider),
        ),
      AppButtonStyle.light => (p.surface, p.accent, null),
      AppButtonStyle.ghost => (
          p.surface.withValues(alpha: .12),
          p.surface,
          Border.all(color: p.surface, width: 1.5),
        ),
    };

    final radius = BorderRadius.circular(pill ? 999 : 12);
    final text = AppStrings.w800(fontSize, 1).c(foreground);

    final Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
      );
    } else if (trailingText != null) {
      content = Row(
        children: [
          Expanded(child: Text(label, style: text)),
          Text(trailingText!, style: text),
        ],
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, style: text, textAlign: TextAlign.center)),
          if (trailingIcon != null) ...[
            const SizedBox(width: 9),
            AppIcon(
              trailingIcon!,
              size: 16,
              color: foreground,
              strokeWidth: 2.4,
            ),
          ],
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: trailingText != null ? 18 : 14,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(border: border, borderRadius: radius),
            child: content,
          ),
        ),
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TextStyle? style;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: style ??
              AppStrings.w800(11.5, 1).c(context.palette.accent),
        ),
      ),
    );
  }
}
