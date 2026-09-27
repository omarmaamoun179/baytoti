import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

class OtpCodeBoxes extends StatelessWidget {
  final String code;
  final int digits;
  final int rejections;

  const OtpCodeBoxes({
    super.key,
    required this.code,
    required this.digits,
    required this.rejections,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final boxes = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          for (var i = 0; i < digits; i++) ...[
            if (i > 0) const SizedBox(width: 9),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    width: 2,
                    color: code.length == i ? p.accent : p.divider,
                  ),
                ),
                child: Text(
                  i < code.length ? code[i] : '',
                  style: AppStrings.w800(24, 1).c(p.text),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey(rejections),
      tween: Tween(begin: rejections == 0 ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0),
        child: child,
      ),
      child: boxes,
    );
  }
}
