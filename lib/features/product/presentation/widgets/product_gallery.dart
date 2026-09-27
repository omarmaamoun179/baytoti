import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/product_badge.dart';
import '../../../catalog/presentation/widgets/product_badge_chip.dart';

class ProductGallery extends StatefulWidget {
  final List<ImageRef> images;
  final ProductBadge? badge;

  const ProductGallery({super.key, required this.images, this.badge});

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final badge = widget.badge;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.length > 1)
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (_, index) => NetworkPhoto(url: images[index].url),
            )
          else
            NetworkPhoto(url: images.firstUrl),
          if (badge != null)
            PositionedDirectional(
              top: 12,
              start: 12,
              child: ProductBadgeChip(badge: badge, large: true),
            ),
          PositionedDirectional(
            bottom: 10,
            end: 10,
            child: _buildBars(context, images.isEmpty ? 1 : images.length),
          ),
        ],
      ),
    );
  }

  Widget _buildBars(BuildContext context, int count) {
    final p = context.palette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Container(
            width: 22,
            height: 3,
            color: i == _page ? p.text : p.neutral500,
          ),
        ],
      ],
    );
  }
}
