import 'market.dart';
import 'validators/validator_logic.dart';

String wirePhone(String phone) => digitsOnly(phone);

String displayPhone(String phone) {
  final digits = digitsOnly(phone);
  final market = Market.ofPhone(digits);
  if (market == null) return phone;

  final local = digits.substring(market.dialCode.length - 1);
  if (local.length != market.nationalLength) return phone;

  final split = switch (market) {
    Market.kw => [local.substring(0, 4), local.substring(4)],
    Market.eg => [
        local.substring(0, 3),
        local.substring(3, 6),
        local.substring(6),
      ],
  };
  return '${market.dialCode} ${split.join(' ')}';
}
