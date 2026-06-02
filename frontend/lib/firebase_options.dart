// GENERADO por: dart run tool/generate_firebase_options.dart
// No editar a mano. Fuente: android/app/google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const bool isConfigured = true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  /// Configura también la app Web en Firebase Console y vuelve a generar.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDeA0wpITSOBXhTdwBBWiFzV-PSMGO6qw0',
    appId: '1:982131503029:android:c3a89d41d96df0893d33fc',
    messagingSenderId: '982131503029',
    projectId: 'heft-c5cae',
    storageBucket: 'heft-c5cae.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDeA0wpITSOBXhTdwBBWiFzV-PSMGO6qw0',
    appId: '1:982131503029:android:c3a89d41d96df0893d33fc',
    messagingSenderId: '982131503029',
    projectId: 'heft-c5cae',
    storageBucket: 'heft-c5cae.firebasestorage.app',
  );

  /// Añade iOS en Firebase, descarga GoogleService-Info.plist y regenera con FlutterFire.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDeA0wpITSOBXhTdwBBWiFzV-PSMGO6qw0',
    appId: '1:982131503029:android:c3a89d41d96df0893d33fc',
    messagingSenderId: '982131503029',
    projectId: 'heft-c5cae',
    storageBucket: 'heft-c5cae.firebasestorage.app',
    iosBundleId: 'com.heft.frontend',
  );
}
