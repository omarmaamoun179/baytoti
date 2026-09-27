import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../domain/entities/home_feed.dart';

class PromotionRail extends StatelessWidget {
  final List<HomeBanner> promotions;
  final ValueChanged<HomeBanner> onTap;

  const PromotionRail({
    super.key,
    required this.promotions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < promotions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _PromotionCard(
              promotion: promotions[i],
              onTap: () => onTap(promotions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final HomeBanner promotion;
  final VoidCallback onTap;

  const _PromotionCard({required this.promotion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final discount = promotion.discountLabel;
    final action = promotion.actionLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkPhoto(url: promotion.imageUrl),
                  if (discount != null)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 7,
                        ),
                        decoration: BoxDecoration(
                          color: p.amberTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discount,
                          style: AppStrings.w800(11, 1).c(p.amberInk),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w800(13, 1.25).c(p.text),
                  ),
                  if (promotion.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      promotion.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStrings.w400(11, 1.4).c(p.neutral700),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: 8),
                    Text(action, style: AppStrings.w800(11, 1).c(p.accent700)),
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
