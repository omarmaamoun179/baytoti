import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon.dart';

class FavouriteButton extends StatelessWidget {
  final bool isFavourite;
  final VoidCallback? onTap;
  final double size;

  const FavouriteButton({
    super.key,
    required this.isFavourite,
    required this.onTap,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = isFavourite ? p.accent : p.neutral600;

    return Semantics(
      button: true,
      selected: isFavourite,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: p.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppIcon(
            AppIcons.heart,
            size: size * 15 / 36,
            color: color,
            strokeWidth: 1.8,
            filled: isFavourite,
          ),
        ),
      ),
    );
  }
}
