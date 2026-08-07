import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/firebase_bootstrap.dart';
import '../../../../app/firestore_paths.dart';
import '../../../../app/l10n/app_strings.dart';

/// Type de notification pour une prière.
enum PrayerNotifMode {
  off,
  vibration,
  takbir,
  adhan;

  String get label => S.notifMode(name);

  static PrayerNotifMode fromName(String? name) {
    return PrayerNotifMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PrayerNotifMode.off,
    );
  }
}

/// Préférences notifications prière (local + cloud `prayer_settings/{uid}`).
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

  static String labelFr(String key) => S.prayerName(key);

  static PrayerNotifMode _defaultFor(String key) {
    if (key == 'sunrise') return PrayerNotifMode.off;
    return PrayerNotifMode.adhan;
  }

  static bool get _canUseCloud {
    if (!firebaseReady) return false;
    return FirebaseAuth.instance.currentUser != null;
  }

  static DocumentReference<Map<String, dynamic>> get _cloudDoc {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection(FirestorePaths.prayerSettings)
        .doc(uid);
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
    await _syncAllToCloud();
  }

  static Future<Map<String, PrayerNotifMode>> getAllModes() async {
    await _hydrateFromCloudIfNeeded();
    return {
      for (final key in prayerKeys) key: await getMode(key),
    };
  }

  static Future<void> _hydrateFromCloudIfNeeded() async {
    if (!_canUseCloud) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLocal = prayerKeys.any(
        (k) => prefs.containsKey('$_prefix$k'),
      );
      if (hasLocal) return;

      final snap = await _cloudDoc.get();
      final modes = snap.data()?['modes'] as Map<String, dynamic>?;
      if (modes == null) return;
      for (final key in prayerKeys) {
        final raw = modes[key] as String?;
        if (raw != null) {
          await prefs.setString('$_prefix$key', raw);
        }
      }
    } catch (_) {}
  }

  static Future<void> _syncAllToCloud() async {
    if (!_canUseCloud) return;
    try {
      final modes = {
        for (final key in prayerKeys) key: (await getMode(key)).name,
      };
      await _cloudDoc.set({
        'modes': modes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
