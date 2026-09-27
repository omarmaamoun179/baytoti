import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../services/cache_service.dart';

class LocalizationService {
  LocalizationService._();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];
  static const Locale fallbackLocale = Locale('en');
  static const Locale defaultLocale = Locale('ar');
  static const String translationsPath = 'assets/translations';

  static Widget wrap(Widget child) {
    return EasyLocalization(
      supportedLocales: supportedLocales,
      path: translationsPath,
      fallbackLocale: fallbackLocale,
      startLocale: defaultLocale,
      saveLocale: true,
      useFallbackTranslations: true,
      ignorePluralRules: false,
      child: ToastificationWrapper(child: child),
    );
  }

  static Future<void> change(
    BuildContext context,
    CacheService cache,
    String languageCode,
  ) async {
    await cache.setLanguageCode(languageCode);
    if (!context.mounted) return;
    await context.setLocale(Locale(languageCode));
  }
}
