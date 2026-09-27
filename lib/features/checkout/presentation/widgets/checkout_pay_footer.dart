import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_button.dart';

class CheckoutPayFooter extends StatelessWidget {
  final String totalDisplay;
  final bool isLoading;
  final VoidCallback? onPay;

  const CheckoutPayFooter({
    super.key,
    required this.totalDisplay,
    required this.isLoading,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'checkout_confirm_pay'.tr(),
            trailingText: totalDisplay,
            height: 54,
            isLoading: isLoading,
            onPressed: onPay,
          ),
          const SizedBox(height: 10),
          Text(
            'checkout_pay_note'.tr(),
            style: AppStrings.w400(11, 1.6).c(p.neutral600),
          ),
        ],
      ),
    );
  }
}
