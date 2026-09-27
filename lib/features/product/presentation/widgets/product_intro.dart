import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../catalog/presentation/widgets/favourite_button.dart';
import '../../domain/entities/product_detail.dart';

class ProductIntro extends StatelessWidget {
  final ProductDetail product;
  final VoidCallback onFavourite;

  const ProductIntro({
    super.key,
    required this.product,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final compareAt = product.compareAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: AppStrings.w800(22, 1.2).c(p.text),
                ),
              ),
              const SizedBox(width: 12),
              FavouriteButton(
                isFavourite: product.isFavourite,
                onTap: onFavourite,
                size: 38,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                product.price.display,
                style: AppStrings.w800(26, 1).c(p.accent700),
              ),
              if (compareAt != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    compareAt.display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w400(12, 1).c(p.neutral600).lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
