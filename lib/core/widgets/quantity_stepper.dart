import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final double height;
  final double buttonWidth;
  final double signSize;
  final double valueSize;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.height = 32,
    this.buttonWidth = 32,
    this.signSize = 15,
    this.valueSize = 13,
  });

  const QuantityStepper.large({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  })  : height = 48,
        buttonWidth = 38,
        signSize = 17,
        valueSize = 14;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget sign(String glyph, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          child: SizedBox(
            width: buttonWidth,
            height: height,
            child: Center(
              child: Text(
                glyph,
                style: AppStrings.w800(signSize, 1)
                    .c(onTap == null ? p.neutral500 : p.text),
              ),
            ),
          ),
        );

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: p.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          sign('−', onDecrement),
          Container(
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: p.hairline),
            ),
            child: Text(
              '$quantity',
              style: AppStrings.w800(valueSize, 1).c(p.text),
            ),
          ),
          sign('+', onIncrement),
        ],
      ),
    );
  }
}
