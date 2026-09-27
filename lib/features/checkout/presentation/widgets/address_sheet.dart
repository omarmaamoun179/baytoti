import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/sheet_handle.dart';
import '../../domain/entities/checkout.dart';
import 'address_card.dart';

Future<String?> showAddressSheet(
  BuildContext context, {
  required List<CheckoutAddress> addresses,
  String? selectedId,
  VoidCallback? onAdd,
}) =>
    showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => AddressSheet(
        addresses: addresses,
        selectedId: selectedId,
        onAdd: onAdd,
      ),
    );

class AddressSheet extends StatelessWidget {
  final List<CheckoutAddress> addresses;
  final String? selectedId;
  final VoidCallback? onAdd;

  const AddressSheet({
    super.key,
    required this.addresses,
    this.selectedId,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maxHeight = MediaQuery.sizeOf(context).height * .7;
    final onAdd = this.onAdd;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetHandle()),
              Text(
                'checkout_address'.tr(),
                style: AppStrings.w800(20, 1.2).c(p.text),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(address.id),
                      behavior: HitTestBehavior.opaque,
                      child: AddressCard(
                        label: address.label,
                        line: address.line,
                        selected: address.id == selectedId,
                      ),
                    );
                  },
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(height: 14),
                AppButton(
                  label: 'address_add'.tr(),
                  trailingIcon: AppIcons.plus,
                  style: AppButtonStyle.outline,
                  height: 46,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAdd();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
