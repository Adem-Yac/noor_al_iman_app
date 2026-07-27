import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA77SzeNswPVrD7F9LOqRNeWQ3zkU38TAo',
    appId: '1:292198966717:web:0833dc7d0bda967d265ed4',
    messagingSenderId: '292198966717',
    projectId: 'noor-al-iman-app',
    authDomain: 'noor-al-iman-app.firebaseapp.com',
    storageBucket: 'noor-al-iman-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOdmKbYvyoSYCADdFXHEL2eRRg6I8-bYU',
    appId: '1:292198966717:android:c582b7099480132e265ed4',
    messagingSenderId: '292198966717',
    projectId: 'noor-al-iman-app',
    storageBucket: 'noor-al-iman-app.firebasestorage.app',
  );
}
