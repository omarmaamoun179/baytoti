import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/pill_chip.dart';
import '../../domain/entities/search_query.dart';

class SearchFilterBar extends StatelessWidget {
  final SearchQuery query;
  final String? categoryName;
  final VoidCallback onAll;
  final VoidCallback onCategory;
  final VoidCallback onPrice;

  const SearchFilterBar({
    super.key,
    required this.query,
    this.categoryName,
    required this.onAll,
    required this.onCategory,
    required this.onPrice,
  });

  @override
  Widget build(BuildContext context) {
    return ChipStrip(
      children: [
        PillChip(
          label: 'search_filter_all'.tr(),
          selected: !query.hasFilters,
          onTap: onAll,
        ),
        PillChip(
          label: categoryName ?? 'search_filter_category'.tr(),
          selected: query.categorySlug != null,
          onTap: onCategory,
        ),
        PillChip(
          label: 'search_filter_price'.tr(),
          selected: query.sort.isByPrice,
          onTap: onPrice,
        ),
      ],
    );
  }
}
