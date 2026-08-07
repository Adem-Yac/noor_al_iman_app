import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_settings.dart';
import 'app/firebase_bootstrap.dart';
import 'features/prayer/data/services/prayer_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseSafely();
  await AppSettings.load();
  // Init notifs hors du chemin critique : l’UI s’affiche tout de suite.
  PrayerNotificationService.instance.init();
  runApp(const NoorAlImanApp());
}
