import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import '../utils/constants.dart';
import 'section_label.dart';

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool hasError;

  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        style: AppStrings.w600(14, 1.2).c(p.text),
        decoration: fieldDecoration(p, hint: hint, hasError: hasError),
      ),
    );
  }
}

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  const PhoneField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasError ? p.danger : p.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border(right: p.hairline)),
              child: Text(
                supportedCountryDialCode,
                style: AppStrings.w800(13, 1).c(p.neutral700),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(localPhoneLength),
                ],
                style: AppStrings.w600(15, 1.2).c(p.text).spaced(.9),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '5150 2244',
                  hintStyle: AppStrings.w600(15, 1.2).c(p.neutral500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration fieldDecoration(
  AppPalette p, {
  String? hint,
  bool hasError = false,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: AppStrings.w600(14, 1.2).c(p.neutral500),
    filled: true,
    fillColor: p.surface,
    counterText: '',
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: border(p.divider),
    enabledBorder: border(hasError ? p.danger : p.divider),
    focusedBorder: border(hasError ? p.danger : p.accent),
  );
}
