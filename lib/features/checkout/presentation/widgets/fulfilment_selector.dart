import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/checkout.dart';

class FulfilmentSelector extends StatelessWidget {
  final List<FulfilmentMethod> methods;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const FulfilmentSelector({
    super.key,
    required this.methods,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final method in methods)
              Expanded(child: _buildCell(context, method)),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, FulfilmentMethod method) {
    final p = context.palette;
    final selected = method.id == selectedId;
    final foreground = selected ? p.onAccent : p.text;

    return Semantics(
      button: true,
      selected: selected,
      enabled: method.available,
      child: Material(
        color: selected ? p.accent : Colors.transparent,
        child: InkWell(
          onTap: method.available ? () => onSelect(method.id) : null,
          child: Opacity(
            opacity: method.available ? 1 : .4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: AppStrings.w800(12, 1.2).c(foreground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.sublabel,
                    style: AppStrings.w400(10, 1.3)
                        .c(foreground.withValues(alpha: .75)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
