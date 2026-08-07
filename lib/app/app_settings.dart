import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales (langue, thème, notifications).
abstract final class AppSettings {
  static const _kLang = 'settings_lang_v1';
  static const _kTheme = 'settings_theme_v1';
  static const _kNotifs = 'settings_notifs_v1';

  static final lang = ValueNotifier<String>('fr');
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static final notificationsEnabled = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLang);
    // Français par défaut (première ouverture ou valeur invalide).
    lang.value = switch (stored) {
      'en' || 'ar' || 'fr' => stored!,
      _ => 'fr',
    };
    if (stored == null) {
      await prefs.setString(_kLang, 'fr');
    }
    final theme = prefs.getString(_kTheme);
    themeMode.value = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notificationsEnabled.value = prefs.getBool(_kNotifs) ?? true;
  }

  static Future<void> setLang(String code) async {
    final next = switch (code) {
      'en' || 'ar' || 'fr' => code,
      _ => 'fr',
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
