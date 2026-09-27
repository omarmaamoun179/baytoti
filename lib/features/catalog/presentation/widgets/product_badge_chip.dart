import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/product_badge.dart';

class ProductBadgeChip extends StatelessWidget {
  final ProductBadge badge;
  final bool large;

  const ProductBadgeChip({super.key, required this.badge, this.large = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final background = switch (badge) {
      ProductBadge.trending => p.amber,
      ProductBadge.bestSeller || ProductBadge.featured => p.accent,
      ProductBadge.newArrival => p.text,
    };
    final label = badge.labelKey.tr();
    final latin = context.locale.languageCode != 'ar';
    final size = large ? 10.0 : 9.0;

    return Container(
      padding: large
          ? const EdgeInsets.symmetric(vertical: 7, horizontal: 10)
          : const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(large ? 9 : 8),
      ),
      child: Text(
        label,
        style: AppStrings.w800(size, 1)
            .c(p.onAccent)
            .spaced(latin ? size * (large ? .08 : .06) : 0),
      ),
    );
  }
}
