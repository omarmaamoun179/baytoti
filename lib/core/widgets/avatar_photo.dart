import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'app_icon.dart';
import 'network_photo.dart';

class AvatarPhoto extends StatelessWidget {
  final String? url;
  final String? filePath;
  final double size;

  const AvatarPhoto({super.key, this.url, this.filePath, this.size = 58});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final path = filePath;
    final placeholder = ColoredBox(
      color: p.neutral200,
      child: Center(
        child: AppIcon(AppIcons.user, size: size * .42, color: p.neutral600),
      ),
    );

    final Widget image;
    if (path != null) {
      image = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => placeholder,
      );
    } else if ((url?.trim() ?? '').isNotEmpty) {
      image = NetworkPhoto(url: url);
    } else {
      image = placeholder;
    }

    return ClipOval(child: SizedBox.square(dimension: size, child: image));
  }
}
