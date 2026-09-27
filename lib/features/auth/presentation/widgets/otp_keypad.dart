import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

class OtpKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const OtpKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget key(String label) {
      if (label.isEmpty) return const SizedBox(height: 54);
      final radius = BorderRadius.circular(12);

      return Material(
        color: p.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => label == '⌫' ? onBackspace() : onDigit(label),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: p.divider),
            ),
            child: Text(label, style: AppStrings.w800(20, 1).c(p.text)),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          for (var row = 0; row < 4; row++) ...[
            if (row > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(child: key(_keys[row * 3 + col])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
