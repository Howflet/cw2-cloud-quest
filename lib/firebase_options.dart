// Firebase options for the LOCAL EMULATOR project "demo-cloud-quest".
//
// The apiKey below is a fake value shaped like a real key (the Android SDK
// checks the format); the emulators never validate it.
// "demo-" project IDs are understood by the Firebase Emulator Suite and never
// touch a real Firebase project, so these placeholder values are safe to commit.
//
// To use the course Firebase project instead, run from the project root:
//   flutterfire configure --project=<course-project-id> --platforms=android,ios
// which overwrites this file with generated values, then run the app with
//   flutter run --dart-define=USE_EMULATORS=false
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Cloud Quest targets Android and iOS only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Cloud Quest targets Android and iOS only.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemo-Local-Emulator-Only-Key00000',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-cloud-quest',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemo-Local-Emulator-Only-Key00000',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-cloud-quest',
    iosBundleId: 'edu.gsu.mad.cloudQuest',
  );
}
