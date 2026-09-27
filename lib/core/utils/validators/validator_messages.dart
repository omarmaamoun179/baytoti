import 'package:easy_localization/easy_localization.dart';

import 'validator_logic.dart';

String? validateRequired(String? value) =>
    (value == null || value.trim().isEmpty) ? 'field_required'.tr() : null;

String? validateTextLength(
  String? value, {
  required int maxLength,
  int minLength = 0,
  bool isRequired = false,
}) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return isRequired ? 'field_required'.tr() : null;

  final length = text.runes.length;
  if (length < minLength) return 'text_too_short'.tr(args: ['$minLength']);
  if (length > maxLength) return 'text_too_long'.tr(args: ['$maxLength']);
  return null;
}

String? validateName(String? value) => switch (checkName(value)) {
      null => null,
      NameError.empty => 'name_required'.tr(),
      NameError.tooShort => 'name_too_short'.tr(),
      NameError.tooLong => 'name_too_long'.tr(),
    };

String? validatePhone(String? value) => switch (checkPhone(value)) {
      null => null,
      PhoneError.empty => 'phone_required'.tr(),
      PhoneError.invalid => 'invalid_phone'.tr(),
    };
