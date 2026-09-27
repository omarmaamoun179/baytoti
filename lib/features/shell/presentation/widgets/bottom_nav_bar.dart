import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

class BottomNavItem {
  final AppIconData icon;
  final String labelKey;

  const BottomNavItem(this.icon, this.labelKey);
}

class BottomNavBar extends StatelessWidget {
  static const items = [
    BottomNavItem(AppIcons.home, 'nav_home'),
    BottomNavItem(AppIcons.explore, 'nav_explore'),
    BottomNavItem(AppIcons.search, 'nav_search'),
    BottomNavItem(AppIcons.bag, 'nav_cart'),
    BottomNavItem(AppIcons.user, 'nav_profile'),
  ];

  static const int cartIndex = 3;

  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : 8),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: p.hairline),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(child: _buildItem(context, i)),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final p = context.palette;
    final item = items[index];
    final color = index == currentIndex ? p.accent : p.neutral600;
    final showBadge = index == cartIndex && cartCount > 0;

    return Semantics(
      button: true,
      selected: index == currentIndex,
      child: InkResponse(
        onTap: () => onTap(index),
        highlightShape: BoxShape.rectangle,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(item.icon, size: 19, color: color, strokeWidth: 1.8),
                  const SizedBox(height: 5),
                  Text(
                    item.labelKey.tr(),
                    maxLines: 1,
                    style: AppStrings.w600(9.5, 1).c(color),
                  ),
                ],
              ),
            ),
            if (showBadge)
              PositionedDirectional(
                top: 6,
                end: 22,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  color: p.accent,
                  child: Text(
                    '$cartCount',
                    style: AppStrings.w800(9, 1).c(p.bg),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
