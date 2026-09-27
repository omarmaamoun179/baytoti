import '../../../core/utils/constants.dart';

String formatPhoneForDisplay(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final dialCode = supportedCountryDialCode.replaceAll('+', '');

  if (!digits.startsWith(dialCode) ||
      digits.length != dialCode.length + localPhoneLength) {
    return phone;
  }

  final local = digits.substring(dialCode.length);
  const half = localPhoneLength ~/ 2;
  return '$supportedCountryDialCode ${local.substring(0, half)} '
      '${local.substring(half)}';
}
