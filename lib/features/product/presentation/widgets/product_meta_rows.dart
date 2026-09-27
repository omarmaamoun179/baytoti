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

  static String? preparation(int? minutes) {
    if (minutes == null || minutes <= 0) return null;
    if (minutes % 60 == 0) {
      return 'product_preparation_hours'.tr(args: ['${minutes ~/ 60}']);
    }
    return 'product_preparation_minutes'.tr(args: ['$minutes']);
  }

  static String? stock(ProductDetail product) {
    if (!product.inStock) return 'product_out_of_stock'.tr();
    final count = product.stock;
    return count == null ? null : 'product_in_stock'.tr(args: ['$count']);
  }

  static String? rating(ProductDetail product) {
    final rating = product.rating;
    if (rating == null) return null;
    final sold = product.soldCount;
    return sold == null
        ? '★ $rating'
        : 'product_rating_value'.tr(args: ['$rating', '$sold']);
  }

  @override
  Widget build(BuildContext context) {
    final fulfilment = fulfilmentKey(product.fulfilment);
    final rows = [
      ('product_rating', rating(product)),
      ('product_stock', stock(product)),
      ('product_preparation', preparation(product.preparationMinutes)),
      ('product_fulfilment', fulfilment?.tr()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final (key, value) in rows)
            if (value != null) _buildRow(context, key.tr(), value),
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
