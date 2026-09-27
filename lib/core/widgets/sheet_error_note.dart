import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

class SheetErrorNote extends StatelessWidget {
  final String message;

  const SheetErrorNote({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.dangerTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: AppStrings.w400(12, 1.6).c(p.danger)),
    );
  }
}
