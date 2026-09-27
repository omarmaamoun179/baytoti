import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../domain/entities/home_feed.dart';

class TrustedStoreRail extends StatelessWidget {
  final List<TrustedStore> stores;
  final ValueChanged<TrustedStore> onTap;

  const TrustedStoreRail({super.key, required this.stores, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stores.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _TrustedStoreCard(
              store: stores[i],
              onTap: () => onTap(stores[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustedStoreCard extends StatelessWidget {
  static const double _bannerHeight = 92;
  static const double _logoSize = 44;

  final TrustedStore store;
  final VoidCallback onTap;

  const _TrustedStoreCard({required this.store, required this.onTap});

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
        width: 184,
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
              height: _bannerHeight + _logoSize / 2,
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
