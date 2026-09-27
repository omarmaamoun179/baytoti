import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/pill_chip.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/search_results.dart';

class SearchFilterBar extends StatelessWidget {
  final SearchQuery query;
  final SearchFacets facets;
  final VoidCallback onAll;
  final VoidCallback onCategory;
  final VoidCallback onPrice;
  final VoidCallback onCity;
  final VoidCallback onRating;

  const SearchFilterBar({
    super.key,
    required this.query,
    required this.facets,
    required this.onAll,
    required this.onCategory,
    required this.onPrice,
    required this.onCity,
    required this.onRating,
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
          label: facets.categoryName(query.categoryId) ??
              'search_filter_category'.tr(),
          selected: query.categoryId != null,
          onTap: onCategory,
        ),
        PillChip(
          label: 'search_filter_price'.tr(),
          selected: query.sort.isByPrice,
          onTap: onPrice,
        ),
        PillChip(
          label: query.city ?? 'search_filter_city'.tr(),
          selected: query.city != null,
          onTap: onCity,
        ),
        PillChip(
          label: 'search_filter_rating'.tr(),
          selected: query.minRating != null,
          onTap: onRating,
        ),
      ],
    );
  }
}
