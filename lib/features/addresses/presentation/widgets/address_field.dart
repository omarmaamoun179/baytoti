import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_text_field.dart';

class AddressField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final String? error;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool multiline;

  const AddressField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLength,
    this.error,
    this.onChanged,
    this.keyboardType,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final error = this.error;

    return LabeledField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (multiline)
            TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 3,
              maxLines: 5,
              maxLength: maxLength,
              keyboardType: TextInputType.multiline,
              style: AppStrings.w600(14, 1.5).c(p.text),
              decoration: fieldDecoration(
                p,
                hint: hint,
                hasError: error != null,
              ),
            )
          else
            AppTextField(
              controller: controller,
              hint: hint,
              maxLength: maxLength,
              keyboardType: keyboardType,
              textInputAction: TextInputAction.next,
              hasError: error != null,
              onChanged: onChanged,
            ),
          if (error != null) FieldErrorText(error),
        ],
      ),
    );
  }
}
