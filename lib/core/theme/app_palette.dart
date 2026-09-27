import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;

  final Color surface;

  final Color text;

  final Color divider;

  final Color accent;

  final Color accent100;

  final Color accent200;

  final Color accent600;

  final Color accent700;

  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;

  final Color neutral600;

  final Color neutral700;

  final Color neutral800;

  final Color amber;

  final Color amberTint;
  final Color amberInk;

  final Color onAccent;

  final Color danger;
  final Color dangerTint;

  final List<BoxShadow> cardShadow;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.text,
    required this.divider,
    required this.accent,
    required this.accent100,
    required this.accent200,
    required this.accent600,
    required this.accent700,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.amber,
    required this.amberTint,
    required this.amberInk,
    required this.onAccent,
    required this.danger,
    required this.dangerTint,
    required this.cardShadow,
  });

  static const AppPalette light = AppPalette(
    bg: AppColors.bg,
    surface: AppColors.surface,
    text: AppColors.text,
    divider: AppColors.divider,
    accent: AppColors.accent,
    accent100: AppColors.accent100,
    accent200: AppColors.accent200,
    accent600: AppColors.accent600,
    accent700: AppColors.accent700,
    neutral200: AppColors.neutral200,
    neutral300: AppColors.neutral300,
    neutral400: AppColors.neutral400,
    neutral500: AppColors.neutral500,
    neutral600: AppColors.neutral600,
    neutral700: AppColors.neutral700,
    neutral800: AppColors.neutral800,
    amber: AppColors.amber,
    amberTint: AppColors.amberTint,
    amberInk: AppColors.amberInk,
    onAccent: AppColors.surface,
    danger: AppColors.danger,
    dangerTint: AppColors.dangerTint,
    cardShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
    ],
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? divider,
    Color? accent,
    Color? accent100,
    Color? accent200,
    Color? accent600,
    Color? accent700,
    Color? neutral200,
    Color? neutral300,
    Color? neutral400,
    Color? neutral500,
    Color? neutral600,
    Color? neutral700,
    Color? neutral800,
    Color? amber,
    Color? amberTint,
    Color? amberInk,
    Color? onAccent,
    Color? danger,
    Color? dangerTint,
    List<BoxShadow>? cardShadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      accent100: accent100 ?? this.accent100,
      accent200: accent200 ?? this.accent200,
      accent600: accent600 ?? this.accent600,
      accent700: accent700 ?? this.accent700,
      neutral200: neutral200 ?? this.neutral200,
      neutral300: neutral300 ?? this.neutral300,
      neutral400: neutral400 ?? this.neutral400,
      neutral500: neutral500 ?? this.neutral500,
      neutral600: neutral600 ?? this.neutral600,
      neutral700: neutral700 ?? this.neutral700,
      neutral800: neutral800 ?? this.neutral800,
      amber: amber ?? this.amber,
      amberTint: amberTint ?? this.amberTint,
      amberInk: amberInk ?? this.amberInk,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      dangerTint: dangerTint ?? this.dangerTint,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  BorderSide get hairline => BorderSide(color: divider);

  BorderSide get rule => BorderSide(color: divider, width: 2);

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) => this;
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
