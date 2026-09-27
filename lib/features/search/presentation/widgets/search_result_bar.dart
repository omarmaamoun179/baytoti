import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/search_query.dart';

class SearchResultBar extends StatelessWidget {
  final int? total;
  final SearchSort sort;
  final VoidCallback onSort;

  const SearchResultBar({
    super.key,
    required this.total,
    required this.sort,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: p.hairline)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == null ? '' : 'search_result_count'.tr(args: ['$total']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStrings.w400(11, 1).c(p.neutral700),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: onSort,
              behavior: HitTestBehavior.opaque,
              child: Text(
                sort.labelKey.tr(),
                style: AppStrings.w800(11, 1).c(p.accent700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
