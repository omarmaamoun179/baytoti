import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/entities/order.dart';

class OrderRatingCard extends StatelessWidget {
  final int rating;
  final bool enabled;
  final ValueChanged<int> onRate;

  const OrderRatingCard({
    super.key,
    required this.rating,
    required this.enabled,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.accent100,
        border: Border.all(color: p.accent200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_rate_title'.tr(),
            style: AppStrings.w800(13, 1.3).c(p.text),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
            child: Text(
              'order_rate_sub'.tr(),
              style: AppStrings.w400(11, 1.6).c(p.neutral700),
            ),
          ),
          Row(
            children: [
              for (var n = RateOrderParams.minRating;
                  n <= RateOrderParams.maxRating;
                  n++) ...[
                if (n > RateOrderParams.minRating) const SizedBox(width: 6),
                _buildStar(context, n),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStar(BuildContext context, int value) {
    final p = context.palette;
    final radius = BorderRadius.circular(10);

    return Semantics(
      button: true,
      selected: value <= rating,
      label: '$value',
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: enabled ? () => onRate(value) : null,
          borderRadius: radius,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: p.divider),
              borderRadius: radius,
            ),
            child: AppIcon(
              AppIcons.star,
              size: 17,
              color: p.accent,
              strokeWidth: 1.5,
              filled: value <= rating,
            ),
          ),
        ),
      ),
    );
  }
}
