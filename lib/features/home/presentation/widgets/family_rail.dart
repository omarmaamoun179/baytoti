import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/image_ref.dart';

class FamilyRail extends StatelessWidget {
  final List<FamilyRef> families;
  final ValueChanged<FamilyRef> onTap;

  const FamilyRail({super.key, required this.families, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < families.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _FamilyCard(
              family: families[i],
              onTap: () => onTap(families[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final FamilyRef family;
  final VoidCallback onTap;

  const _FamilyCard({required this.family, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final meta = [
      ?family.city,
      if (family.productCount != null)
        'family_product_count'.tr(args: ['${family.productCount}']),
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 176,
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.divider),
          borderRadius: BorderRadius.circular(16),
          boxShadow: p.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 96,
              child: NetworkPhoto(url: family.images.firstUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w800(13, 1.25).c(p.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w400(11, 1.4).c(p.neutral700),
                  ),
                  if (family.rating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppIcon(
                          AppIcons.star,
                          size: 12,
                          color: p.accent,
                          strokeWidth: 0,
                          filled: true,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          family.rating!.toStringAsFixed(1),
                          style: AppStrings.w800(11, 1).c(p.text),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
