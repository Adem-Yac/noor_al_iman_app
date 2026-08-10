import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales (langue, thème, notifications, onboarding, offline).
abstract final class AppSettings {
  static const _kLang = 'settings_lang_v1';
  static const _kTheme = 'settings_theme_v1';
  static const _kNotifs = 'settings_notifs_v1';
  static const _kOnboarding = 'settings_onboarding_done_v1';
  static const _kOfflineBrowse = 'settings_offline_browse_v1';

  static final lang = ValueNotifier<String>('ar');
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static final notificationsEnabled = ValueNotifier<bool>(true);
  static final onboardingDone = ValueNotifier<bool>(false);
  /// Lecteur hors ligne du contenu déjà téléchargé (Coran / Douas / Hadiths).
  static final offlineBrowseEnabled = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLang);
    // Arabe par défaut (première ouverture ou valeur invalide).
    lang.value = switch (stored) {
      'en' || 'ar' || 'fr' => stored!,
      _ => 'ar',
    };
    if (stored == null) {
      await prefs.setString(_kLang, 'ar');
    }
    final theme = prefs.getString(_kTheme);
    themeMode.value = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notificationsEnabled.value = prefs.getBool(_kNotifs) ?? true;
    onboardingDone.value = prefs.getBool(_kOnboarding) ?? false;
    offlineBrowseEnabled.value = prefs.getBool(_kOfflineBrowse) ?? true;
  }

  static Future<void> setOnboardingDone(bool done) async {
    onboardingDone.value = done;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarding, done);
  }

  static Future<void> setOfflineBrowseEnabled(bool enabled) async {
    offlineBrowseEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOfflineBrowse, enabled);
  }

  static Future<void> setLang(String code) async {
    final next = switch (code) {
      'en' || 'ar' || 'fr' => code,
      _ => 'ar',
    };
    lang.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, next);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifs, enabled);
  }
}
