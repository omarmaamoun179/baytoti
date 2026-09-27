import 'package:flutter/material.dart';

import '../../../catalog/domain/entities/product_summary.dart';
import '../../../catalog/presentation/widgets/product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductSummary> products;
  final ValueChanged<ProductSummary> onOpen;
  final ValueChanged<ProductSummary> onAdd;
  final bool compact;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onOpen,
    required this.onAdd,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < products.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _card(products[i])),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < products.length
                    ? _card(products[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _card(ProductSummary product) => ProductCard(
        product: product,
        compact: compact,
        onTap: () => onOpen(product),
        onAdd: () => onAdd(product),
      );
}
