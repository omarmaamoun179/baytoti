import 'package:flutter/material.dart';

import '../../../catalog/domain/entities/product_summary.dart';
import '../../../catalog/presentation/widgets/product_card.dart';

class FamilyProductRow extends StatelessWidget {
  static const double gap = 10;

  final List<ProductSummary> products;
  final ValueChanged<ProductSummary> onOpen;
  final ValueChanged<ProductSummary> onAdd;

  const FamilyProductRow({
    super.key,
    required this.products,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            Expanded(
              child: i < products.length
                  ? ProductCard(
                      product: products[i],
                      compact: true,
                      onTap: () => onOpen(products[i]),
                      onAdd: () => onAdd(products[i]),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}
