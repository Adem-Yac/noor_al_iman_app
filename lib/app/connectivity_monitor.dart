import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'offline_prefetch_service.dart';
import 'user_data_sync_service.dart';

/// Suit l’état réseau : sync cloud + prefetch Wi‑Fi hors ligne.
abstract final class ConnectivityMonitor {
  static final online = ValueNotifier<bool>(true);
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final current = await Connectivity().checkConnectivity();
      _apply(current, syncIfBackOnline: false);
      Connectivity().onConnectivityChanged.listen(
        (results) => _apply(results, syncIfBackOnline: true),
      );
      // Sync Firestore si écritures locales en attente (SharedPreferences).
      unawaited(UserDataSyncService.syncIfPending());
      // Premier téléchargement auto après démarrage (Wi‑Fi).
      unawaited(
        Future<void>.delayed(const Duration(seconds: 4), () {
          return OfflinePrefetchService.prefetchIfWifi();
        }),
      );
    } catch (e) {
      debugPrint('ConnectivityMonitor.start: $e');
      online.value = true;
    }
  }

  static void _apply(
    List<ConnectivityResult> results, {
    required bool syncIfBackOnline,
  }) {
    final next = results.any((r) => r != ConnectivityResult.none);
    final wasOffline = !online.value;
    online.value = next;
    if (syncIfBackOnline && wasOffline && next) {
      unawaited(UserDataSyncService.syncAll());
    }
    final wifi = results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    if (wifi) {
      unawaited(OfflinePrefetchService.prefetchIfWifi());
    }
  }
}
