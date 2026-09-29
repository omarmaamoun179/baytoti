import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../domain/entities/order.dart';

class OrderItemsSection extends StatelessWidget {
  final List<OrderLine> items;
  final String totalDisplay;
  final Map<String, ImageRef> productPhotos;
  final ValueChanged<OrderLine>? onReview;
  final Set<String> reviewedProductIds;

  const OrderItemsSection({
    super.key,
    required this.items,
    required this.totalDisplay,
    this.productPhotos = const {},
    this.onReview,
    this.reviewedProductIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = AppStrings.w800(14, 1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: p.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel('order_items'.tr()),
          const SizedBox(height: 12),
          for (final line in items) _buildLine(context, line),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text('order_total'.tr(), style: total.c(p.text)),
                ),
                Text(totalDisplay, style: total.c(p.accent700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(BuildContext context, OrderLine line) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: p.hairline)),
      child: Row(
        children: [
          // SizedBox(
          //   width: 48,
          //   height: 48,
          //   child: NetworkPhoto(
          //     url: (line.image ?? productPhotos[line.productId])?.url,
          //   ),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: AppStrings.w600(12, 1.3).c(p.text)),
                const SizedBox(height: 3),
                Text(
                  '× ${line.quantity}',
                  style: AppStrings.w400(11, 1.3).c(p.neutral600),
                ),
                if (onReview != null && line.productId != null)
                  _buildReview(line),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(line.lineTotal.display, style: AppStrings.w800(12, 1).c(p.text)),
        ],
      ),
    );
  }

  Widget _buildReview(OrderLine line) {
    final reviewed = reviewedProductIds.contains(line.productId);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: AppTextButton(
        label: (reviewed ? 'order_review_edit' : 'order_review_item').tr(),
        onPressed: () => onReview!(line),
      ),
    );
  }
}
