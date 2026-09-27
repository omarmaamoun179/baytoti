import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

class StatItem {
  final String value;
  final String label;

  const StatItem(this.value, this.label);
}

class StatGrid extends StatelessWidget {
  final List<StatItem> items;

  const StatGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(border: Border(bottom: p.rule)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: BorderDirectional(end: p.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.value, style: AppStrings.w800(20, 1).c(p.text)),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        style: AppStrings.w400(10, 1.3).c(p.neutral700),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
