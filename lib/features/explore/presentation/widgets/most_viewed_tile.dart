import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/product_summary.dart';

final RegExp _whitespace = RegExp(r'\s+');

class MostViewedTile extends StatelessWidget {
  final ProductSummary product;
  final VoidCallback onTap;

  const MostViewedTile({super.key, required this.product, required this.onTap});

  static String labelOf(String name) => name.trim().split(_whitespace).first;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: product.name,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(url: product.images.firstUrl),
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labelOf(product.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: AppStrings.w800(9, 1.2).c(p.onAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
