import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/order.dart';

class OrderTimeline extends StatelessWidget {
  final List<OrderTimelineStep> steps;

  const OrderTimeline({super.key, required this.steps});

  static String statusLabel(OrderStatus status) =>
      'order_status_${status.wire}'.tr();

  static String formatAt(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year} '
        '${two(at.hour)}:${two(at.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _buildStep(
              context,
              steps[i],
              isLast: i == steps.length - 1,
              nextDone: i + 1 < steps.length && steps[i + 1].done,
            ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    OrderTimelineStep step, {
    required bool isLast,
    required bool nextDone,
  }) {
    final p = context.palette;
    final done = step.done;
    final at = step.at;
    final caption = at != null
        ? formatAt(at)
        : done
            ? null
            : 'order_pending'.tr();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: done ? p.accent : p.bg,
                border: Border.all(
                  color: done ? p.accent : p.neutral400,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 42,
                color: nextDone ? p.accent : p.neutral300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel(step.status),
                  style: AppStrings.w800(13, 1.2)
                      .c(done ? p.text : p.neutral600),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: AppStrings.w400(11, 1.5).c(p.neutral600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
