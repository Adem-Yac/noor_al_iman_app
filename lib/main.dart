import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_prefs.dart';
import 'app/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseSafely();
  final onboarded = await AppPrefs.isOnboarded();
  runApp(NoorAlImanApp(onboarded: onboarded));
}
