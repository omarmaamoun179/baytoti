import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../domain/entities/address.dart';

class AddressCountryPicker extends StatelessWidget {
  static const List<(String, String)> _countries = [
    (Address.kuwait, 'country_kuwait'),
    (Address.egypt, 'country_egypt'),
  ];

  final String value;
  final ValueChanged<String> onChanged;
  final String? error;

  const AddressCountryPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final error = this.error;

    return LabeledField(
      label: 'address_field_country'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (country, key) in _countries)
                PillChip(
                  label: key.tr(),
                  selected: value == country,
                  onTap: () => onChanged(country),
                ),
            ],
          ),
          if (error != null) FieldErrorText(error),
        ],
      ),
    );
  }
}
