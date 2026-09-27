import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/stat_grid.dart';
import '../../domain/entities/family_profile.dart';

class FamilyStats extends StatelessWidget {
  static final NumberFormat _compact = NumberFormat.compact(locale: 'en')
    ..significantDigitsInUse = false
    ..maximumFractionDigits = 1;

  final FamilyProfile family;

  const FamilyStats({super.key, required this.family});

  static String compact(int count) => _compact.format(count).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return StatGrid(
      items: [
        StatItem('${family.productCount}', 'family_stat_products'.tr()),
        StatItem(family.rating?.toString() ?? '–', 'family_stat_rating'.tr()),
        StatItem(compact(family.followerCount), 'family_stat_followers'.tr()),
      ],
    );
  }
}
