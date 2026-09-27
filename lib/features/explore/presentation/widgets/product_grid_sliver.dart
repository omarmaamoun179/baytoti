import 'package:flutter/material.dart';

import '../../../catalog/domain/entities/product_summary.dart';
import '../../../catalog/presentation/widgets/product_card.dart';

class ProductGridSliver extends StatelessWidget {
  final List<ProductSummary> products;
  final ValueChanged<ProductSummary> onOpen;
  final ValueChanged<ProductSummary> onAdd;

  const ProductGridSliver({
    super.key,
    required this.products,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: (products.length + 1) ~/ 2,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, row) {
        final first = row * 2;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _card(products[first])),
              const SizedBox(width: 10),
              Expanded(
                child: first + 1 < products.length
                    ? _card(products[first + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(ProductSummary product) => ProductCard(
        product: product,
        onTap: () => onOpen(product),
        onAdd: () => onAdd(product),
      );
}
