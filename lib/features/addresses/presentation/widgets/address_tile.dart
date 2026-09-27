import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/phone.dart';
import '../../domain/entities/address.dart';

class AddressTile extends StatelessWidget {
  final Address address;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMakeDefault;

  const AddressTile({
    super.key,
    required this.address,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
    required this.onMakeDefault,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final recipient = address.recipientName;
    final phone = address.phone;

    return IgnorePointer(
      ignoring: isBusy,
      child: AnimatedOpacity(
        opacity: isBusy ? .55 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(
              color: address.isDefault ? p.accent : p.divider,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: p.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(context),
              const SizedBox(height: 6),
              Text(
                address.line,
                style: AppStrings.w400(12, 1.6).c(p.neutral700),
              ),
              if (recipient.isNotEmpty || phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (recipient.isNotEmpty) recipient,
                    if (phone.isNotEmpty) '\u2066${displayPhone(phone)}\u2069',
                  ].join(' · '),
                  style: AppStrings.w400(11.5, 1.5).c(p.neutral600),
                ),
              ],
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Flexible(
          child: Text(
            address.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStrings.w800(13.5, 1.3).c(p.text),
          ),
        ),
        if (address.isDefault) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p.accent100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'address_default_badge'.tr(),
              style: AppStrings.w800(9.5, 1).c(p.accent700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        _action('address_edit'.tr(), p.text, onEdit),
        const SizedBox(width: 16),
        _action('address_delete'.tr(), p.danger, onDelete),
        const Spacer(),
        if (!address.isDefault)
          _action('address_make_default'.tr(), p.accent700, onMakeDefault),
      ],
    );
  }

  Widget _action(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, style: AppStrings.w800(11.5, 1).c(color)),
        ),
      );
}
