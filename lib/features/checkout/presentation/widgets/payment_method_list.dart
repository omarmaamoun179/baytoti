import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/checkout.dart';

class PaymentMethodList extends StatelessWidget {
  final List<PaymentMethod> methods;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const PaymentMethodList({
    super.key,
    required this.methods,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final method in methods)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTile(context, method),
          ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, PaymentMethod method) {
    final p = context.palette;
    final selected = method.id == selectedId;
    final radius = BorderRadius.circular(12);

    return Semantics(
      button: true,
      selected: selected,
      enabled: method.available,
      child: Opacity(
        opacity: method.available ? 1 : .4,
        child: Material(
          color: p.bg,
          borderRadius: radius,
          child: InkWell(
            onTap: method.available ? () => onSelect(method.id) : null,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: selected
                    ? Border.all(color: p.accent, width: 2)
                    : Border.all(color: p.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? p.accent : p.neutral500,
                        width: 2,
                      ),
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      color: selected ? p.accent : Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method.label,
                      style: AppStrings.w600(13, 1.2).c(p.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    method.meta,
                    style: AppStrings.w400(10, 1).c(p.neutral600),
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
