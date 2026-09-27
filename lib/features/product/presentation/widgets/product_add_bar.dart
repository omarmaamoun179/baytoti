import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/quantity_stepper.dart';

class ProductAddBar extends StatelessWidget {
  final int priceFils;
  final int quantity;
  final bool enabled;
  final bool isAdding;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback onAdd;

  const ProductAddBar({
    super.key,
    required this.priceFils,
    required this.quantity,
    required this.enabled,
    required this.isAdding,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final lineTotal = Money.format(priceFils * quantity);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: p.hairline),
      ),
      child: Row(
        children: [
          QuantityStepper.large(
            quantity: quantity,
            onDecrement: enabled ? onDecrement : null,
            onIncrement: enabled ? onIncrement : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: 'product_add_to_cart'.tr(),
              trailingText: lineTotal,
              height: 48,
              fontSize: 13,
              isLoading: isAdding,
              onPressed: enabled ? onAdd : null,
            ),
          ),
        ],
      ),
    );
  }
}
