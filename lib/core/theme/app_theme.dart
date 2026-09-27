import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_strings.dart';
import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light);

  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle.dark;

  static ThemeData _build(AppPalette p) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.amber,
      onSecondary: p.onAccent,
      error: p.danger,
      onError: p.onAccent,
      surface: p.surface,
      onSurface: p.text,
      surfaceContainerHighest: p.neutral200,
      outline: p.divider,
      outlineVariant: p.neutral400,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: AppStrings.fontFamily,
      fontFamilyFallback: AppStrings.fontFamilyFallback,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      splashFactory: InkRipple.splashFactory,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: overlayStyle,
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.text),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent200,
        selectionHandleColor: p.accent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0x80000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      textTheme: _textTheme(p),
    );
  }

  static TextTheme _textTheme(AppPalette p) => TextTheme(
        headlineMedium: AppStrings.w800(24, 1.2).c(p.text),
        titleLarge: AppStrings.w800(19, 1.25).c(p.text),
        titleMedium: AppStrings.w800(17, 1.2).c(p.text),
        titleSmall: AppStrings.w800(13, 1.3).c(p.text),
        bodyLarge: AppStrings.w400(13, 1.75).c(p.neutral800),
        bodyMedium: AppStrings.w400(12, 1.6).c(p.neutral800),
        bodySmall: AppStrings.w400(11, 1.4).c(p.neutral700),
        labelLarge: AppStrings.w800(14, 1).c(p.text),
        labelMedium: AppStrings.w600(12, 1.2).c(p.text),
        labelSmall: AppStrings.w400(10, 1.3).c(p.neutral600),
      );
}
