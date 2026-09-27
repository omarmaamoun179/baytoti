import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../../catalog/presentation/widgets/favourite_button.dart';

class SearchResultRow extends StatelessWidget {
  final ProductSummary product;
  final VoidCallback onOpen;
  final VoidCallback onFavourite;

  const SearchResultRow({
    super.key,
    required this.product,
    required this.onOpen,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final city = product.family.city;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: Border(bottom: p.hairline)),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: NetworkPhoto(url: product.images.firstUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppStrings.w600(13, 1.3).c(p.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    city == null || city.isEmpty
                        ? product.family.name
                        : '${product.family.name} · $city',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w400(11, 1.4).c(p.neutral600),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    product.price.display,
                    style: AppStrings.w800(13, 1).c(p.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          FavouriteButton(
            isFavourite: product.isFavourite,
            onTap: onFavourite,
            size: 36,
          ),
        ],
      ),
    );
  }
}
