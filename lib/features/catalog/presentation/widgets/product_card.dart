import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../domain/entities/image_ref.dart';
import '../../domain/entities/product_summary.dart';
import 'product_badge_chip.dart';

class ProductCard extends StatelessWidget {
  final ProductSummary product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final badge = product.badge;

    return Container(
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
          GestureDetector(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkPhoto(url: product.images.firstUrl),
                  if (badge != null && !compact)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: ProductBadgeChip(badge: badge),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w600(12, 1.35).c(p.text),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.family.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w400(10, 1.3).c(p.neutral600),
                  ),
                ],
                SizedBox(height: compact ? 7 : 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.price.display,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStrings.w800(compact ? 13 : 14, 1).c(p.text),
                      ),
                    ),
                    AddButton(onTap: onAdd, size: compact ? 28 : 30),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const AddButton({super.key, required this.onTap, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: AppIcon(
              AppIcons.plus,
              size: size * 14 / 30,
              color: p.onAccent,
              strokeWidth: 2.4,
            ),
          ),
        ),
      ),
    );
  }
}
