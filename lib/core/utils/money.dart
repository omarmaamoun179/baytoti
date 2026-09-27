import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import 'market.dart';

class Money extends Equatable {
  final int fils;

  const Money({required this.fils});

  static String languageCode = 'ar';

  static Market market = Market.fallback;

  factory Money.of(Map<String, dynamic> json, String key) =>
      Money(fils: _fils(json[key]));

  static Money? maybeOf(Map<String, dynamic> json, String key) =>
      json[key] == null ? null : Money.of(json, key);

  static Money? parse(Object? value) =>
      value == null ? null : Money(fils: _fils(value));

  String get display => format(fils);

  static int _fils(Object? value) => switch (value) {
        final num amount => (amount * 1000).round(),
        final String amount =>
          ((double.tryParse(amount.replaceAll(',', '')) ?? 0) * 1000).round(),
        _ => 0,
      };

  static String format(int fils, [String? language, Market? on]) {
    final m = on ?? market;
    final pattern = m.decimals == 0 ? '0' : '0.${'0' * m.decimals}';
    final amount = NumberFormat(pattern, 'en').format(fils / 1000);
    return '$amount ${m.currency(language ?? languageCode)}';
  }

  @override
  List<Object?> get props => [fils];
}
