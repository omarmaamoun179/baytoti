import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIconData {
  final String elements;
  final bool mirrorInRtl;

  const AppIconData(this.elements, {this.mirrorInRtl = false});
}

class AppIcons {
  AppIcons._();

  static const back = AppIconData('<path d="M15 18l-6-6 6-6"/>', mirrorInRtl: true);
  static const forward = AppIconData('<path d="M9 6l6 6-6 6"/>', mirrorInRtl: true);
  static const bell = AppIconData(
    '<path d="M18 8a6 6 0 10-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 01-3.4 0"/>',
  );
  static const search = AppIconData(
    '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>',
  );
  static const heart = AppIconData(
    '<path d="M20.8 5.6a5 5 0 00-7.1 0L12 7.3l-1.7-1.7a5 5 0 10-7.1 7.1l8.8 8.8 8.8-8.8a5 5 0 000-7.1z"/>',
  );
  static const star = AppIconData(
    '<path d="M12 2l3 6.5 7 .9-5 4.8 1.2 7L12 18l-6.2 3.2L7 14.2l-5-4.8 7-.9z"/>',
  );
  static const plus = AppIconData('<path d="M12 5v14M5 12h14"/>');
  static const close = AppIconData('<path d="M18 6L6 18M6 6l12 12"/>');
  static const check = AppIconData('<path d="M5 12.5l5 5 9-10"/>');
  static const home = AppIconData(
    '<path d="M3 10l9-7 9 7v10a1 1 0 01-1 1h-5v-7H9v7H4a1 1 0 01-1-1z"/>',
  );
  static const explore = AppIconData(
    '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>',
  );
  static const bag = AppIconData(
    '<path d="M6 2l-2 5v13a2 2 0 002 2h12a2 2 0 002-2V7l-2-5z"/><path d="M4 7h16M16 11a4 4 0 01-8 0"/>',
  );
  static const user = AppIconData(
    '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3.6-6 8-6s8 2 8 6"/>',
  );
  static const eye = AppIconData(
    '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>'
    '<circle cx="12" cy="12" r="3"/>',
  );
  static const eyeOff = AppIconData(
    '<path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 '
    '0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 '
    '01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><path d="M1 1l22 22"/>',
  );
}

class AppIcon extends StatelessWidget {
  final AppIconData icon;
  final double size;
  final Color color;
  final double strokeWidth;
  final bool filled;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = 16,
    required this.color,
    this.strokeWidth = 2,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final paint = SvgPaint.of(color);
    final fill = filled ? '${paint.hex}" fill-opacity="${paint.opacity}' : 'none';
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="$fill" stroke="${paint.hex}" '
        'stroke-opacity="${paint.opacity}" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">'
        '${icon.elements}</svg>';

    final picture = SvgPicture.string(svg, width: size, height: size);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return icon.mirrorInRtl && rtl
        ? Transform.flip(flipX: true, child: picture)
        : picture;
  }
}

class SvgPaint {
  final String hex;
  final String opacity;

  const SvgPaint(this.hex, this.opacity);

  factory SvgPaint.of(Color color) {
    final argb = color.toARGB32();
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final alpha = ((argb >> 24) & 0xFF) / 255;
    return SvgPaint('#$rgb', alpha.toStringAsFixed(3));
  }
}
