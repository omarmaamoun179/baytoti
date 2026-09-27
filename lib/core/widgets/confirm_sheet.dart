import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_button.dart';
import 'sheet_handle.dart';

Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => ConfirmSheet(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
    ),
  );
  return confirmed ?? false;
}

class ConfirmSheet extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;

  const ConfirmSheet({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SheetHandle()),
            Text(title, style: AppStrings.w800(20, 1.2).c(p.text)),
            const SizedBox(height: 8),
            Text(body, style: AppStrings.w400(12.5, 1.7).c(p.neutral700)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'go_back'.tr(),
                    style: AppButtonStyle.quiet,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
