import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class Money extends Equatable {
  final int fils;

  final String display;

  const Money({required this.fils, required this.display});

  factory Money.of(Map<String, dynamic> json, String key) {
    final fils = (json['${key}_fils'] as num).toInt();
    return Money(
      fils: fils,
      display: json['${key}_display'] as String? ?? format(fils, 'ar'),
    );
  }

  static Money? maybeOf(Map<String, dynamic> json, String key) =>
      json['${key}_fils'] == null ? null : Money.of(json, key);

  static final NumberFormat _amount = NumberFormat('0.000', 'en');

  static String format(int fils, String languageCode) =>
      '${_amount.format(fils / 1000)} ${languageCode == 'ar' ? 'د.ك' : 'KWD'}';

  @override
  List<Object?> get props => [fils, display];
}
