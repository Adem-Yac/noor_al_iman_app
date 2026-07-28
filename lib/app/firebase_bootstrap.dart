import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// True after a successful Firebase init (Android / iOS / Web).
bool firebaseReady = false;

Future<void> initFirebaseSafely() async {
  // Windows/Linux desktop: firebase_core pigeon channel often fails.
  final supported = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  if (!supported) {
    firebaseReady = false;
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e, st) {
    debugPrint('Firebase init skipped: $e\n$st');
    firebaseReady = false;
  }
}
