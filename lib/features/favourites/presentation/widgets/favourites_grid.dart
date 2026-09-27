import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../../catalog/presentation/widgets/product_card.dart';

class FavouritesGrid extends StatelessWidget {
  final List<ProductSummary> products;
  final ValueChanged<ProductSummary> onOpen;
  final ValueChanged<ProductSummary> onAdd;
  final ValueChanged<ProductSummary> onRemove;

  const FavouritesGrid({
    super.key,
    required this.products,
    required this.onOpen,
    required this.onAdd,
    required this.onRemove,
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
              Expanded(child: _card(context, products[i])),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < products.length
                    ? _card(context, products[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _card(BuildContext context, ProductSummary product) {
    final p = context.palette;

    return Stack(
      fit: StackFit.expand,
      children: [
        ProductCard(
          key: ValueKey(product.id),
          product: product,
          onTap: () => onOpen(product),
          onAdd: () => onAdd(product),
        ),
        PositionedDirectional(
          top: 8,
          end: 8,
          child: Material(
            color: p.surface,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onRemove(product),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: AppIcon(
                  AppIcons.heart,
                  size: 16,
                  color: p.danger,
                  strokeWidth: 0,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
