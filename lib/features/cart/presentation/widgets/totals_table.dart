import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../catalog/domain/entities/order_totals.dart';

class TotalsTable extends StatelessWidget {
  final OrderTotals totals;

  const TotalsTable({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final row = AppStrings.w400(12.5, 1);

    return Column(
      children: [
        _buildRow(
          context,
          'cart_subtotal'.tr(),
          totals.subtotal.display,
          row.c(p.neutral800),
        ),
        if (totals.discount.fils != 0)
          _buildRow(
            context,
            'cart_discount'.tr(),
            '− ${totals.discount.display}',
            row.c(p.accent700),
          ),
        if (totals.shipping.fils != 0)
          _buildRow(
            context,
            'cart_shipping'.tr(),
            totals.shipping.display,
            row.c(p.neutral800),
          ),
        _buildRow(
          context,
          'cart_total'.tr(),
          totals.total.display,
          AppStrings.w800(14, 1).c(p.text),
        ),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value,
    TextStyle style,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: context.palette.hairline),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}
