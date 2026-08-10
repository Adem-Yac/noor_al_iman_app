import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// True after a successful Firebase init (Android / iOS / Web).
bool firebaseReady = false;

Future<void> initFirebaseSafely() async {
  // Windows/Linux desktop: firebase_core pigeon channel often fails.
  final supported = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ;

  if (!supported) {
    firebaseReady = false;
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Cache Firestore local pour lectures offline des docs cloud.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    firebaseReady = true;
  } catch (e, st) {
    debugPrint('Firebase init skipped: $e\n$st');
    firebaseReady = false;
  }
}
