import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class Money extends Equatable {
  final int fils;

  final String display;

  const Money({required this.fils, required this.display});

  factory Money.of(Map<String, dynamic> json, String key) {
    final fils = _fils(json[key]);
    return Money(fils: fils, display: format(fils, 'ar'));
  }

  static Money? maybeOf(Map<String, dynamic> json, String key) =>
      json[key] == null ? null : Money.of(json, key);

  static int _fils(Object? value) => switch (value) {
        final num amount => (amount * 1000).round(),
        final String amount => ((double.tryParse(amount) ?? 0) * 1000).round(),
        _ => 0,
      };

  static final NumberFormat _amount = NumberFormat('0.000', 'en');

  static String format(int fils, String languageCode) =>
      '${_amount.format(fils / 1000)} ${languageCode == 'ar' ? 'د.ك' : 'KWD'}';

  @override
  List<Object?> get props => [fils, display];
}
