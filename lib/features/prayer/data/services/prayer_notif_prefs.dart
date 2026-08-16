import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/firebase_bootstrap.dart';
import '../../../../app/firestore_paths.dart';
import '../../../../app/l10n/app_strings.dart';
import '../../../../app/user_data_sync_service.dart';

/// Type de notification pour une prière.
enum PrayerNotifMode {
  off,
  vibration,
  takbir,
  adhan;

  String get label => S.notifMode(name);

  static PrayerNotifMode fromName(String? name) {
    // Ancien mode « on » → adhan.
    if (name == 'on') return PrayerNotifMode.adhan;
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
    await syncToCloud();
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
      final snap = await _cloudDoc.get();
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final rawModes = data['modes'];
      final modes = rawModes is Map
          ? Map<String, dynamic>.from(rawModes)
          : data;
      final prefs = await SharedPreferences.getInstance();
      for (final key in prayerKeys) {
        final raw = modes[key];
        if (raw is! String) continue;
        await prefs.setString(
          '$_prefix$key',
          PrayerNotifMode.fromName(raw).name,
        );
      }
    } catch (_) {}
  }

  static Future<void> syncToCloud() async {
    if (!_canUseCloud) return;
    try {
      final modes = {
        for (final key in prayerKeys) key: (await getMode(key)).name,
      };
      await _cloudDoc.set({
        'modes': modes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await UserDataSyncService.clearPending();
    } catch (_) {
      await UserDataSyncService.markPending();
    }
  }
}
