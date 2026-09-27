import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../catalog/domain/entities/category.dart';

class CategoryRail extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onTap;

  const CategoryRail({
    super.key,
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _CategoryTile(
              category: categories[i],
              onTap: () => onTap(categories[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final amber = category.icon.tinted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.divider),
          borderRadius: BorderRadius.circular(14),
          boxShadow: p.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 66,
              alignment: Alignment.center,
              color: amber ? p.amberTint : p.accent100,
              child: AppIcon(
                AppIconData('<path d="${category.icon.path}"/>'),
                size: 26,
                strokeWidth: 1.5,
                color: amber ? p.amberInk : p.accent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStrings.w600(11, 1.2).c(p.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
