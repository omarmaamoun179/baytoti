import 'constants.dart';
import 'validators/validator_logic.dart';

String toE164(String localDigits) =>
    '$supportedCountryDialCode${digitsOnly(localDigits)}';

String displayPhone(String phone) {
  final digits = digitsOnly(phone);
  final dial = digitsOnly(supportedCountryDialCode);
  final local = digits.startsWith(dial) ? digits.substring(dial.length) : null;

  if (local == null || local.length != localPhoneLength) return phone;
  return '$supportedCountryDialCode ${local.substring(0, 4)} ${local.substring(4)}';
}
