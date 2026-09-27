import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

class CheckoutStepStrip extends StatelessWidget {
  static const List<String> _steps = [
    'checkout_step_address',
    'checkout_step_fulfilment',
    'checkout_step_payment',
  ];

  const CheckoutStepStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(border: Border(bottom: p.rule)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _steps.length; i++)
              Expanded(child: _buildCell(context, i)),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int index) {
    final p = context.palette;
    final active = index == 0;
    final foreground = active ? p.onAccent : p.neutral700;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      decoration: BoxDecoration(
        color: active ? p.accent : Colors.transparent,
        border: BorderDirectional(end: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (index + 1).toString().padLeft(2, '0'),
            style: AppStrings.w800(9, 1).c(foreground),
          ),
          const SizedBox(height: 5),
          Text(
            _steps[index].tr(),
            style: AppStrings.w600(10, 1.2).c(foreground),
          ),
        ],
      ),
    );
  }
}
