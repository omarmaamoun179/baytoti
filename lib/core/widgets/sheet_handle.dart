import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.palette.neutral400,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
