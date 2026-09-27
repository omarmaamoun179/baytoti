import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_palette.dart';
import 'app_icon.dart';

class BaytoutiMark extends StatelessWidget {
  final double width;

  const BaytoutiMark({super.key, this.width = 96});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final green = SvgPaint.of(p.accent).hex;
    final amber = SvgPaint.of(p.amber).hex;

    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 86" '
        'fill="none">'
        '<path d="M14 40L48 13l34 27" stroke="$green" stroke-width="5.5" '
        'stroke-linecap="round" stroke-linejoin="round"/>'
        '<path d="M21 38v32h54V38" stroke="$green" stroke-width="5.5" '
        'stroke-linecap="round" stroke-linejoin="round"/>'
        '<path d="M40 70V54h16v16" stroke="$green" stroke-width="5" '
        'stroke-linecap="round" stroke-linejoin="round"/>'
        '<path d="M44 30c0-7 5-12 11-13-1 8-5 12-11 13z" fill="$green"/>'
        '<path d="M62 24c3.6 0 6 2.4 6 5.6 0 3.4-2.8 6.4-6.4 6.4-1.2 '
        '0-2.4-.4-3.2-1l-3.4 1.4 1.2-3.2c-.6-1-1-2.2-1-3.4 0-3.2 3.2-5.8 '
        '6.8-5.8z" fill="$amber"/>'
        '</svg>';

    return SvgPicture.string(svg, width: width, height: width * 86 / 96);
  }
}

class BaytoutiTile extends StatelessWidget {
  final double size;

  const BaytoutiTile({super.key, this.size = 82});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final green = SvgPaint.of(p.accent).hex;

    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" '
        'fill="none" stroke="$green" stroke-width="2.6" '
        'stroke-linecap="round" stroke-linejoin="round">'
        '<path d="M7 21L24 8l17 13"/><path d="M11 20v19h26V20"/>'
        '<path d="M19 39V28h10v11"/><path d="M18 15.5h12" stroke-width="2"/>'
        '</svg>';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(size * 24 / 82),
        boxShadow: const [
          BoxShadow(color: Color(0x24000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: SvgPicture.string(svg, width: size * 42 / 82, height: size * 42 / 82),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 13});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final green = SvgPaint.of(p.accent).hex;
    final white = SvgPaint.of(p.onAccent).hex;

    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '<path d="M12 1l2.6 2.1 3.3-.3.9 3.2 2.8 1.8-1.4 3 1.4 3-2.8 1.8-.9 '
        '3.2-3.3-.3L12 23l-2.6-2.1-3.3.3-.9-3.2L2.4 16l1.4-3-1.4-3 2.8-1.8.9'
        '-3.2 3.3.3z" fill="$green"/>'
        '<path d="M8.5 12.3l2.3 2.3 4.7-4.7" stroke="$white" stroke-width="2" '
        'fill="none"/></svg>';

    return SvgPicture.string(svg, width: size, height: size);
  }
}
