enum Market {
  kw(
    iso: 'KW',
    dialCode: '+965',
    nationalLength: 8,
    decimals: 3,
    currencyAr: 'د.ك',
    currencyEn: 'KWD',
  ),
  eg(
    iso: 'EG',
    dialCode: '+20',
    nationalLength: 10,
    decimals: 2,
    currencyAr: 'ج.م',
    currencyEn: 'EGP',
  );

  final String iso;
  final String dialCode;
  final int nationalLength;
  final int decimals;
  final String currencyAr;
  final String currencyEn;

  const Market({
    required this.iso,
    required this.dialCode,
    required this.nationalLength,
    required this.decimals,
    required this.currencyAr,
    required this.currencyEn,
  });

  static const Market fallback = Market.kw;

  static List<String> get isoCodes => [for (final m in values) m.iso];

  static Map<String, int> get nationalLengths =>
      {for (final m in values) m.iso: m.nationalLength};

  static Market fromIso(String? code) => values.firstWhere(
        (m) => m.iso == code?.trim().toUpperCase(),
        orElse: () => fallback,
      );

  static Market? ofPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    for (final m in values) {
      if (digits.startsWith(m.dialCode.substring(1))) return m;
    }
    return null;
  }

  String currency(String languageCode) =>
      languageCode == 'ar' ? currencyAr : currencyEn;
}
