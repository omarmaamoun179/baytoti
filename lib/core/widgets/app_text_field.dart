import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';
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

class AppTextField extends StatefulWidget {
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscureText;

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    if (old.obscureText != widget.obscureText) _hidden = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final secret = widget.obscureText;

    return SizedBox(
      height: 48,
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        obscureText: _hidden,
        autocorrect: !secret,
        enableSuggestions: !secret,
        style: AppStrings.w600(14, 1.2).c(p.text),
        decoration: fieldDecoration(
          p,
          hint: widget.hint,
          hasError: widget.hasError,
        ).copyWith(suffixIcon: secret ? _buildToggle(p) : null),
      ),
    );
  }

  Widget _buildToggle(AppPalette p) => IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        tooltip: (_hidden ? 'password_show' : 'password_hide').tr(),
        icon: AppIcon(
          _hidden ? AppIcons.eye : AppIcons.eyeOff,
          size: 18,
          color: p.neutral600,
        ),
      );
}

class AppTextFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String value)? validator;
  final String? serverError;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final bool obscureText;

  const AppTextFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.serverError,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) => validator?.call(controller.text),
      builder: (field) {
        final error = field.errorText ?? serverError;

        return LabeledField(
          label: label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: controller,
                hint: hint,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                maxLength: maxLength,
                obscureText: obscureText,
                hasError: error != null,
                onChanged: (value) {
                  field.didChange(value);
                  onChanged?.call(value);
                },
              ),
              if (error != null) FieldErrorText(error),
            ],
          ),
        );
      },
    );
  }
}

class FieldErrorText extends StatelessWidget {
  final String message;

  const FieldErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: AppStrings.w400(11, 1.5).c(context.palette.danger),
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
