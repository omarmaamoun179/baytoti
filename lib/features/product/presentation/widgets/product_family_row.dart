import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/image_ref.dart';

class ProductFamilyRow extends StatelessWidget {
  final FamilyRef family;
  final ImageRef? avatar;
  final VoidCallback onTap;

  const ProductFamilyRow({
    super.key,
    required this.family,
    this.avatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rating = family.rating;
    final meta = [
      ?family.city,
      if (rating != null) '★ $rating',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(border: Border(top: p.rule, bottom: p.rule)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: NetworkPhoto(url: avatar?.url),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            family.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStrings.w800(13, 1.2).c(p.text),
                          ),
                        ),
                        if (family.isVerified) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(size: 13),
                        ],
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStrings.w400(11, 1.4).c(p.neutral700),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'product_visit_store'.tr(),
                style: AppStrings.w800(11, 1).c(p.accent700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
