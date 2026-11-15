import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Emulators are on by default. Pass --dart-define=USE_EMULATORS=false after
/// running `flutterfire configure` for the course project.
const bool useEmulators = bool.fromEnvironment(
  'USE_EMULATORS',
  defaultValue: true,
);

/// Android emulator reaches the host at 10.0.2.2; the iOS simulator uses
/// localhost. For a physical device pass your computer's LAN IP:
///   flutter run --dart-define=EMULATOR_HOST=192.168.1.20
const String _hostOverride = String.fromEnvironment('EMULATOR_HOST');

String get emulatorHost {
  if (_hostOverride.isNotEmpty) return _hostOverride;
  return defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulators) {
    // Connect each service once, before any Auth/Firestore/Functions request.
    final host = emulatorHost;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    debugPrint('Cloud Quest: using Firebase emulators at $host');
  }

  runApp(const CloudQuestApp());
}
