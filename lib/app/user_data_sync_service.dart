import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/repositories/user_repository.dart';
import '../features/hadith/data/repositories/hadith_repository.dart';
import '../features/home/data/services/location_service.dart';
import '../features/prayer/data/services/prayer_notif_prefs.dart';
import '../features/quran/data/services/quran_user_data_service.dart';
import 'firebase_bootstrap.dart';

/// Pousse les données locales vers Firestore quand le réseau revient.
abstract final class UserDataSyncService {
  static const pendingKey = 'pending_cloud_sync_v1';
  static bool _running = false;

  static Future<void> markPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(pendingKey, true);
    } catch (_) {}
  }

  static Future<void> clearPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(pendingKey, false);
    } catch (_) {}
  }

  /// Sync complète (idempotente). Appelée au login et au retour online.
  static Future<void> syncAll() async {
    if (!firebaseReady) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_running) return;
    _running = true;
    try {
      final users = UserRepository();
      await users.syncFromAuthUser(user);

      try {
        final location = await LocationService().requestAndSave();
        await users.syncLocation(location);
      } catch (e) {
        debugPrint('UserDataSyncService location: $e');
      }

      await QuranUserDataService().pushLocalToCloud();
      await PrayerNotifPrefs.syncToCloud();
      await HadithRepository().pushFavoritesToCloud();

      await clearPending();
      debugPrint('UserDataSyncService: sync OK');
    } catch (e) {
      debugPrint('UserDataSyncService.syncAll: $e');
      await markPending();
    } finally {
      _running = false;
    }
  }
}
