import 'package:shared_preferences/shared_preferences.dart';

/// Type de notification pour une prière.
enum PrayerNotifMode {
  off,
  vibration,
  takbir,
  adhan;

  String get label => switch (this) {
    PrayerNotifMode.off => 'Désactivé',
    PrayerNotifMode.vibration => 'Vibration',
    PrayerNotifMode.takbir => 'Takbir',
    PrayerNotifMode.adhan => 'Adhan',
  };

  static PrayerNotifMode fromName(String? name) {
    return PrayerNotifMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PrayerNotifMode.off,
    );
  }
}

/// Préférences notifications prière (persistées).
abstract final class PrayerNotifPrefs {
  static const _prefix = 'prayer_notif_';

  static const prayerKeys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static PrayerNotifMode _defaultFor(String key) {
    if (key == 'sunrise') return PrayerNotifMode.off;
    return PrayerNotifMode.adhan;
  }

  static Future<PrayerNotifMode> getMode(String prayerKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$prayerKey');
    if (raw == null) return _defaultFor(prayerKey);
    return PrayerNotifMode.fromName(raw);
  }

  static Future<void> setMode(String prayerKey, PrayerNotifMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$prayerKey', mode.name);
  }

  static Future<Map<String, PrayerNotifMode>> getAllModes() async {
    return {
      for (final key in prayerKeys) key: await getMode(key),
    };
  }
}
