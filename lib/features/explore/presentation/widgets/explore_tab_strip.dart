import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/explore_feed.dart';

class ExploreTabStrip extends StatelessWidget {
  final ExploreTab selected;
  final ValueChanged<ExploreTab> onSelect;

  const ExploreTabStrip({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(border: Border(bottom: p.rule)),
      child: Row(
        children: [
          for (final tab in ExploreTab.values)
            Expanded(child: _buildCell(p, tab, tab == selected)),
        ],
      ),
    );
  }

  Widget _buildCell(AppPalette p, ExploreTab tab, bool isSelected) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? p.accent : Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(tab),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
            decoration: BoxDecoration(
              border: BorderDirectional(end: p.hairline),
            ),
            child: Text(
              tab.labelKey.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppStrings.w800(11, 1)
                  .c(isSelected ? p.onAccent : p.text),
            ),
          ),
        ),
      ),
    );
  }
}
