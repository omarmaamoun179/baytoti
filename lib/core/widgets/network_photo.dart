import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class NetworkPhoto extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Color? placeholderColor;

  const NetworkPhoto({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholderColor,
  });

  static bool isBundled(String source) => source.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final source = url?.trim() ?? '';
    final placeholder = ColoredBox(
      color: placeholderColor ?? context.palette.neutral300,
      child: const SizedBox.expand(),
    );
    if (source.isEmpty) return placeholder;

    if (isBundled(source)) {
      return Image.asset(
        source,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, _, _) => placeholder,
      );
    }

    return CachedNetworkImage(
      imageUrl: source,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => placeholder,
      errorWidget: (context, _, _) => placeholder,
    );
  }
}
