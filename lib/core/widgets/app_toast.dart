import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';

void showAppToast(
  BuildContext context,
  String message, {
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final p = context.palette;
  final action = actionLabel == null || onAction == null
      ? null
      : SnackBarAction(
          label: actionLabel,
          textColor: p.accent200,
          onPressed: onAction,
        );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text,
        elevation: 0,
        action: action,
        persist: false,
        duration: action == null ? _readingTime(message) : _actionTime,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            AppIcon(
              isError ? AppIcons.close : AppIcons.check,
              size: 16,
              strokeWidth: 3,
              color: isError ? p.dangerTint : p.accent200,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: AppStrings.w600(12.5, 1.45).c(p.bg)),
            ),
          ],
        ),
      ),
    );
}

const Duration _actionTime = Duration(seconds: 5);

Duration _readingTime(String message) {
  const base = Duration(milliseconds: 2400);
  const perLine = Duration(milliseconds: 900);
  const cap = Duration(seconds: 8);

  final extraLines = message.split('\n').length - 1;
  if (extraLines <= 0) return base;

  final total = base + perLine * extraLines;
  return total > cap ? cap : total;
}
