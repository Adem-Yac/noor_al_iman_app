import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'user_data_sync_service.dart';

/// Suit l’état réseau et déclenche la sync cloud au retour en ligne.
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
  }
}
