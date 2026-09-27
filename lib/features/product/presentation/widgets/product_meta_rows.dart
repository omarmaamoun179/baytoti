import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/product_detail.dart';

class ProductMetaRows extends StatelessWidget {
  final ProductDetail product;

  const ProductMetaRows({super.key, required this.product});

  static String? fulfilmentKey(Set<Fulfilment> methods) {
    final delivery = methods.contains(Fulfilment.delivery);
    final pickup = methods.contains(Fulfilment.pickup);
    if (delivery && pickup) return 'fulfilment_delivery_or_pickup';
    if (delivery) return 'fulfilment_delivery';
    if (pickup) return 'fulfilment_pickup';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rating = product.rating;
    final fulfilment = fulfilmentKey(product.fulfilment);
    final rows = [
      if (rating != null)
        (
          'product_rating'.tr(),
          'product_rating_value'.tr(args: ['$rating', '${product.soldCount}']),
        ),
      (
        'product_stock'.tr(),
        product.inStock
            ? 'product_in_stock'.tr(args: ['${product.stock}'])
            : 'product_out_of_stock'.tr(),
      ),
      if (product.preparationTime.isNotEmpty)
        ('product_preparation'.tr(), product.preparationTime),
      if (fulfilment != null) ('product_fulfilment'.tr(), fulfilment.tr()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final (key, value) in rows) _buildRow(context, key, value),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String key, String value) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: p.hairline)),
      child: Row(
        children: [
          Text(key, style: AppStrings.w400(12, 1).c(p.neutral700)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppStrings.w800(12, 1).c(p.text),
            ),
          ),
        ],
      ),
    );
  }
}
