import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/entities/order.dart';
import 'order_timeline.dart';

class OrderSummaryTile extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;

  const OrderSummaryTile({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final status = order.status;
    final store = order.family?.name ?? '';
    final cancelled = status == OrderStatus.cancelled;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: p.hairline)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.reference,
                    style: AppStrings.w800(13.5, 1.2).c(p.text),
                  ),
                  if (store.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStrings.w400(11.5, 1.3).c(p.neutral700),
                    ),
                  ],
                  if (status != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 9,
                      ),
                      decoration: BoxDecoration(
                        color: cancelled ? p.dangerTint : p.accent100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        OrderTimeline.statusLabel(status),
                        style: AppStrings.w800(10, 1)
                            .c(cancelled ? p.danger : p.accent700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(order.total.display, style: AppStrings.w800(13, 1).c(p.text)),
            const SizedBox(width: 8),
            AppIcon(AppIcons.forward, size: 14, color: p.neutral500),
          ],
        ),
      ),
    );
  }
}
