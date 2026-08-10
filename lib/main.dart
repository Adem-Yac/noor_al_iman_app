import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/app_settings.dart';
import 'app/connectivity_monitor.dart';
import 'app/firebase_bootstrap.dart';
import 'features/prayer/data/services/prayer_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    initializeDateFormatting('fr'),
    initializeDateFormatting('en'),
    initializeDateFormatting('ar'),
  ]);
  await initFirebaseSafely();
  await AppSettings.load();
  await ConnectivityMonitor.start();
  // Init notifs hors du chemin critique : l’UI s’affiche tout de suite.
  PrayerNotificationService.instance.init();
  runApp(const NoorAlImanApp());
}
