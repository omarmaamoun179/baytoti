import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';

class AddressCard extends StatelessWidget {
  final String label;
  final String? line;
  final bool selected;

  const AddressCard({
    super.key,
    required this.label,
    this.line,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final line = this.line;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: selected ? p.accent : p.divider),
        borderRadius: BorderRadius.circular(14),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppStrings.w800(13, 1.3).c(p.text)),
          if (line != null && line.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(line, style: AppStrings.w400(12, 1.6).c(p.neutral700)),
          ],
        ],
      ),
    );
  }
}

class NoAddressCard extends StatelessWidget {
  final VoidCallback? onAdd;

  const NoAddressCard({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddressCard(label: 'checkout_no_address'.tr()),
        const SizedBox(height: 10),
        AppButton(
          label: 'address_add'.tr(),
          trailingIcon: AppIcons.plus,
          style: AppButtonStyle.outline,
          height: 46,
          onPressed: onAdd,
        ),
      ],
    );
  }
}
