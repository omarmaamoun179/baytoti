import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/stat_grid.dart';

class FamilyStats extends StatelessWidget {
  final int? productCount;
  final double? rating;

  const FamilyStats({super.key, this.productCount, this.rating});

  static List<StatItem> itemsFor({int? productCount, double? rating}) => [
        if (productCount != null)
          StatItem('$productCount', 'family_stat_products'.tr()),
        if (rating != null) StatItem('$rating', 'family_stat_rating'.tr()),
      ];

  @override
  Widget build(BuildContext context) {
    final items = itemsFor(productCount: productCount, rating: rating);
    if (items.isEmpty) return const SizedBox.shrink();

    return StatGrid(items: items);
  }
}
