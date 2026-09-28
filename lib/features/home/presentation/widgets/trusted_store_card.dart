import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../domain/entities/home_feed.dart';

class TrustedStoreCard extends StatelessWidget {
  static const double railWidth = 184;
  static const double _bannerHeight = 92;
  static const double _logoSize = 44;
  static const double imageHeight = _bannerHeight + _logoSize / 2;

  final TrustedStore store;
  final VoidCallback onTap;
  final double? width;

  const TrustedStoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.width,
  });

  String get _meta {
    final family = store.family;
    final meta = [
      ?family.city,
      if (family.productCount != null)
        'family_product_count'.tr(args: ['${family.productCount}']),
    ].join(' · ');
    return meta.isEmpty ? store.description : meta;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final family = store.family;
    final logo = family.images.firstUrl;
    final meta = _meta;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
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
              height: imageHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    bottom: _logoSize / 2,
                    child: NetworkPhoto(url: store.bannerUrl ?? logo),
                  ),
                  PositionedDirectional(
                    start: 10,
                    bottom: 0,
                    width: _logoSize,
                    height: _logoSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.neutral300,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.surface, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NetworkPhoto(url: logo),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 11),
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
                          style: AppStrings.w800(13, 1.25).c(p.text),
                        ),
                      ),
                      if (family.isVerified) ...[
                        const SizedBox(width: 5),
                        const VerifiedBadge(),
                      ],
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStrings.w400(11, 1.45).c(p.neutral700),
                    ),
                  ],
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
