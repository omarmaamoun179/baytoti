import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
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
  final bool obscureText;

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
    this.obscureText = false,
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
        obscureText: obscureText,
        style: AppStrings.w600(14, 1.2).c(p.text),
        decoration: fieldDecoration(p, hint: hint, hasError: hasError),
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
