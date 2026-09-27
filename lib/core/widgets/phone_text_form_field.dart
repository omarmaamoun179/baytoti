import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'section_label.dart';

class PhoneTextFormField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? requiredMessage;
  final String? invalidMessage;
  final String Function(int digits)? lengthMessage;
  final Map<String, int> nationalLengths;
  final String? Function(String?)? validator;
  final ValueChanged<PhoneNumber>? onInputChanged;
  final ValueChanged<String>? onSubmitted;
  final List<String> countries;
  final String initialIsoCode;
  final String? initialNumber;
  final bool enabled;
  final TextInputAction textInputAction;
  final AutovalidateMode autovalidateMode;
  final double height;
  final double radius;
  final double? selectorWidth;
  final String dialCodeSample;

  const PhoneTextFormField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.requiredMessage,
    this.invalidMessage,
    this.lengthMessage,
    this.nationalLengths = const {'KW': 8, 'EG': 10},
    this.validator,
    this.onInputChanged,
    this.onSubmitted,
    this.countries = const ['KW', 'EG'],
    this.initialIsoCode = 'KW',
    this.initialNumber,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.height = 48,
    this.radius = 12,
    this.selectorWidth,
    this.dialCodeSample = '+965',
  });

  @override
  State<PhoneTextFormField> createState() => _PhoneTextFormFieldState();
}

class _PhoneTextFormFieldState extends State<PhoneTextFormField> {
  static const double _flagWidth = 32;
  static const double _flagGap = 12;
  static const double _buttonTrailing = 8;
  static const double _measureSlack = 2;
  static const double _leadingPadding = 15;

  String? _errorText;
  bool _isValidNumber = false;
  PhoneNumber? _number;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChanged);
    _placeInitialNumber();
  }

  Future<void> _placeInitialNumber() async {
    final digits = (widget.initialNumber ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    try {
      final number = await PhoneNumber.getRegionInfoFromPhoneNumber('+$digits');
      if (!mounted || !widget.countries.contains(number.isoCode)) return;

      setState(() {
        _initialValue = PhoneNumber(
          phoneNumber: number.phoneNumber,
          isoCode: number.isoCode,
        );
      });
    } on Exception {
      return;
    }
  }

  @override
  void didUpdateWidget(PhoneTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      widget.focusNode?.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus ?? true) return;
    _reformat();
  }

  Future<void> _reformat() async {
    final controller = widget.controller;
    final number = _number;

    if (controller == null ||
        !_isValidNumber ||
        number?.phoneNumber == null ||
        number?.isoCode == null) {
      return;
    }

    try {
      final formatted = await PhoneNumber.getParsableNumber(number!);
      if (!mounted || formatted.isEmpty || formatted == controller.text) return;
      controller.text = formatted;
    } on Exception {
      return;
    }
  }

  bool get _isEmpty => widget.controller?.text.trim().isEmpty ?? true;

  bool get _hasFocus => widget.focusNode?.hasFocus ?? false;

  int? get _nationalLength {
    final number = _number?.phoneNumber;
    if (number == null) return null;

    final digits = number.replaceAll(RegExp(r'\D'), '');
    final dialCode = (_number?.dialCode ?? '').replaceAll(RegExp(r'\D'), '');

    if (dialCode.isEmpty || !digits.startsWith(dialCode)) return digits.length;
    return digits.length - dialCode.length;
  }

  late PhoneNumber _initialValue = PhoneNumber(
    isoCode: widget.initialIsoCode,
  );

  double _measureSelector(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: widget.dialCodeSample, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return _leadingPadding +
        _flagWidth +
        _flagGap +
        painter.width.ceilToDouble() +
        _buttonTrailing +
        _measureSlack;
  }

  String? _check(String? value) {
    if ((value ?? '').trim().isEmpty) return widget.requiredMessage;

    final expected = widget.nationalLengths[_number?.isoCode];
    final actual = _nationalLength;

    if (widget.lengthMessage != null &&
        expected != null &&
        actual != null &&
        actual != expected) {
      return widget.lengthMessage!(expected);
    }

    if (widget.invalidMessage != null && !_isValidNumber) {
      return widget.invalidMessage;
    }

    return widget.validator?.call(value);
  }

  String? _validate(String? value) {
    final error = _check(value);

    if (error != _errorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _errorText = error);
      });
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          SectionLabel(widget.label!),
          const SizedBox(height: 8),
        ],
        _buildField(context),
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Text(_errorText!, style: AppStrings.w400(11, 1.5).c(p.danger)),
        ],
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    final p = context.palette;
    final selectorWidth =
        widget.selectorWidth ??
        _measureSelector(context, _selectorTextStyle(context));

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          _buildInput(context, selectorWidth),
          PositionedDirectional(
            start: selectorWidth,
            top: 10,
            bottom: 10,
            child: Container(width: 1, color: p.divider),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, double selectorWidth) {
    final p = context.palette;

    return InternationalPhoneNumberInput(
      countries: widget.countries,
      initialValue: _initialValue,
      textFieldController: widget.controller,
      focusNode: widget.focusNode,
      isEnabled: widget.enabled,
      keyboardAction: widget.textInputAction,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      autoValidateMode: AutovalidateMode.onUserInteraction,
      validator: _validate,
      onInputChanged: (number) {
        _number = number;
        widget.onInputChanged?.call(number);
      },
      onInputValidated: (isValid) => _isValidNumber = isValid,
      onFieldSubmitted: widget.onSubmitted,

      locale: Localizations.localeOf(context).languageCode,
      cursorColor: p.accent,

      textAlign: Directionality.of(context) == TextDirection.rtl
          ? TextAlign.end
          : TextAlign.start,
      textStyle: AppStrings.w600(13, 1.2).c(widget.enabled ? p.text : p.neutral500),
      selectorTextStyle: _selectorTextStyle(context),
      errorMessage: _isEmpty && !_hasFocus
          ? widget.requiredMessage
          : widget.invalidMessage,
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        setSelectorButtonAsPrefixIcon: true,
        useBottomSheetSafeArea: true,
        leadingPadding: _leadingPadding,
        trailingSpace: false,
      ),
      searchBoxDecoration: _searchDecoration(context),
      inputDecoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppStrings.w400(13, 1.2).c(p.neutral500),
        filled: true,
        fillColor: p.surface,
        counterText: '',

        contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 0, 15, 0),

        prefixIconConstraints: BoxConstraints.tightFor(
          width: selectorWidth,
          height: widget.height,
        ),
        border: _border(p.divider),
        enabledBorder: _border(p.divider),
        focusedBorder: _border(p.accent),
        disabledBorder: _border(p.divider),
        errorBorder: _border(p.danger),
        focusedErrorBorder: _border(p.danger),

        errorStyle: const TextStyle(fontSize: 0, height: 0),
      ),
    );
  }

  TextStyle _selectorTextStyle(BuildContext context) {
    final p = context.palette;
    return AppStrings.w800(13, 1).c(widget.enabled ? p.text : p.neutral500);
  }

  InputDecoration _searchDecoration(BuildContext context) {
    final p = context.palette;

    return InputDecoration(
      hintText: 'search_by_country'.tr(),
      hintStyle: AppStrings.w400(13, 1.2).c(p.neutral500),
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.neutral500),
      border: _border(p.divider),
      enabledBorder: _border(p.divider),
      focusedBorder: _border(p.accent),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(widget.radius),
    borderSide: BorderSide(
      color: color,
      width: color == context.palette.accent ? 1.5 : 1,
    ),
  );
}
