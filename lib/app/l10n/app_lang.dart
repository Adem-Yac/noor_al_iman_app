import 'package:flutter/material.dart';

import '../app_settings.dart';

/// Langue de l’app (FR / EN / AR).
enum AppLanguage { fr, en, ar }

abstract final class AppLang {
  static AppLanguage get current {
    return switch (AppSettings.lang.value) {
      'en' => AppLanguage.en,
      'ar' => AppLanguage.ar,
      _ => AppLanguage.fr,
    };
  }

  static Locale get locale => Locale(AppSettings.lang.value);

  /// Locale Material sans RTL (l’arabe ne retourne pas la navbar / les pages).
  static Locale get materialLocale =>
      isArabic ? const Locale('fr') : locale;

  static bool get isArabic => current == AppLanguage.ar;

  /// Afficher la traduction sous le texte arabe (jamais en arabe).
  static bool get showTranslation => !isArabic;

  /// Layout toujours LTR (même si la langue est l’arabe).
  static TextDirection get textDirection => TextDirection.ltr;

  static List<Locale> get supportedLocales => const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ];

  /// Traduction de contenu selon la langue (null si arabe ou vide).
  static String? contentTranslation({
    String? french,
    String? english,
    String? fallback,
  }) {
    if (!showTranslation) return null;
    final fr = french?.trim() ?? '';
    final en = english?.trim() ?? '';
    final fb = fallback?.trim() ?? '';
    return switch (current) {
      AppLanguage.fr => fr.isNotEmpty ? fr : (fb.isNotEmpty ? fb : (en.isNotEmpty ? en : null)),
      AppLanguage.en => en.isNotEmpty ? en : (fb.isNotEmpty ? fb : (fr.isNotEmpty ? fr : null)),
      AppLanguage.ar => null,
    };
  }
}
