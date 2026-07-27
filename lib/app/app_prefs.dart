import 'package:shared_preferences/shared_preferences.dart';

/// Préférences app (onboarding, etc.).
abstract final class AppPrefs {
  static const _kOnboarded = 'onboarding_done';

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboarded) ?? false;
  }

  static Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarded, true);
  }
}
