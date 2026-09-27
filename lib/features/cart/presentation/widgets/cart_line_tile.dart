import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../domain/entities/cart.dart';

class CartLineTile extends StatelessWidget {
  final CartItem item;
  final bool busy;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  const CartLineTile({
    super.key,
    required this.item,
    required this.busy,
    required this.onQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: p.hairline)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: NetworkPhoto(url: item.image?.url),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppStrings.w600(13, 1.35).c(p.text)),
                if (item.family.name.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.family.name,
                    style: AppStrings.w400(11, 1.4).c(p.neutral600),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    QuantityStepper(
                      quantity: item.quantity,
                      onDecrement: busy || !item.canDecrement
                          ? null
                          : () => onQuantity(item.quantity - 1),
                      onIncrement: busy || !item.canIncrement
                          ? null
                          : () => onQuantity(item.quantity + 1),
                    ),
                    const Spacer(),
                    Text(
                      item.lineTotal.display,
                      style: AppStrings.w800(14, 1).c(p.text),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            enabled: !busy,
            child: InkWell(
              onTap: busy ? null : onRemove,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 28,
                height: 28,
                child: Center(
                  child: AppIcon(
                    AppIcons.close,
                    size: 14,
                    color: p.neutral600,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
