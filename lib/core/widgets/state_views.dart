import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_button.dart';

class LoadingView extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const LoadingView({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 70),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.palette.accent,
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message ?? 'unexpected_error'.tr(),
            textAlign: TextAlign.center,
            style: AppStrings.w400(12.5, 1.7).c(p.neutral700),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: AppButton(
                label: 'retry'.tr(),
                onPressed: onRetry,
                style: AppButtonStyle.quiet,
                height: 44,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
