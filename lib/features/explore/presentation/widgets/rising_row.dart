import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/presentation/widgets/product_badge_chip.dart';
import '../../domain/entities/explore_feed.dart';

const String _arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';

String rankLabel(int rank, String languageCode) {
  final digits = '$rank';
  if (languageCode != 'ar') return digits;
  return String.fromCharCodes([
    for (final unit in digits.codeUnits)
      unit >= 0x30 && unit <= 0x39
          ? _arabicIndicDigits.codeUnitAt(unit - 0x30)
          : unit,
  ]);
}

class RisingRow extends StatelessWidget {
  final RisingProduct item;
  final String languageCode;
  final VoidCallback onTap;

  const RisingRow({
    super.key,
    required this.item,
    required this.languageCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final product = item.product;
    final badge = product.badge;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: p.hairline)),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 26),
              child: Text(
                rankLabel(item.rank, languageCode),
                style: AppStrings.w800(20, 1).c(p.accent),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 56,
              height: 56,
              child: NetworkPhoto(url: product.images.firstUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppStrings.w600(13, 1.3).c(p.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.family.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w400(11, 1.4).c(p.neutral600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (badge != null) ...[
                        ProductBadgeChip(badge: badge),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        item.growth,
                        style: AppStrings.w800(11, 1).c(p.accent700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              product.price.display,
              style: AppStrings.w800(13, 1).c(p.text),
            ),
          ],
        ),
      ),
    );
  }
}
