import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_button.dart';
import 'app_icon.dart';
import 'avatar_photo.dart';

class AvatarPicker extends StatelessWidget {
  static const double size = 88;

  final String label;
  final String? url;
  final String? filePath;
  final String? error;
  final VoidCallback? onPick;

  const AvatarPicker({
    super.key,
    required this.label,
    this.url,
    this.filePath,
    this.error,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final error = this.error;

    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              children: [
                AvatarPhoto(url: url, filePath: filePath, size: size),
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: p.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.bg, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      AppIcons.plus,
                      size: 14,
                      color: p.onAccent,
                      strokeWidth: 2.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppTextButton(label: label, onPressed: onPick),
        if (error != null)
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppStrings.w400(11, 1.5).c(p.danger),
          ),
      ],
    );
  }
}
