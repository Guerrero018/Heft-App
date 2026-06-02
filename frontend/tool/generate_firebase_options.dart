// Genera lib/firebase_options.dart desde android/app/google-services.json
//
// Uso (desde frontend/):
//   dart run tool/generate_firebase_options.dart

import 'dart:convert';
import 'dart:io';

const _packageName = 'com.heft.frontend';
const _googleServicesPath = 'android/app/google-services.json';
const _outputPath = 'lib/firebase_options.dart';

void main() {
  final file = File(_googleServicesPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'No se encontró $_googleServicesPath\n'
      'Descárgalo desde Firebase Console → Project settings → Your apps → Android (com.heft.frontend)',
    );
    exit(1);
  }

  final root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final projectInfo = root['project_info'] as Map<String, dynamic>;
  final clients = (root['client'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic>? androidClient;
  for (final client in clients) {
    final info = client['client_info'] as Map<String, dynamic>?;
    final android = info?['android_client_info'] as Map<String, dynamic>?;
    if (android?['package_name'] == _packageName) {
      androidClient = client;
      break;
    }
  }

  androidClient ??= clients.isNotEmpty ? clients.first : null;
  if (androidClient == null) {
    stderr.writeln('No hay clientes en google-services.json');
    exit(1);
  }

  final clientInfo = androidClient['client_info'] as Map<String, dynamic>;
  final apiKeys = (androidClient['api_key'] as List).cast<Map<String, dynamic>>();
  final apiKey = apiKeys.first['current_key'] as String;
  final appId = clientInfo['mobilesdk_app_id'] as String;
  final projectId = projectInfo['project_id'] as String;
  final messagingSenderId = projectInfo['project_number'] as String;
  final storageBucket = projectInfo['storage_bucket'] as String;

  final content = '''
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
    apiKey: '$apiKey',
    appId: '$appId',
    messagingSenderId: '$messagingSenderId',
    projectId: '$projectId',
    storageBucket: '$storageBucket',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$apiKey',
    appId: '$appId',
    messagingSenderId: '$messagingSenderId',
    projectId: '$projectId',
    storageBucket: '$storageBucket',
  );

  /// Añade iOS en Firebase, descarga GoogleService-Info.plist y regenera con FlutterFire.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '$apiKey',
    appId: '$appId',
    messagingSenderId: '$messagingSenderId',
    projectId: '$projectId',
    storageBucket: '$storageBucket',
    iosBundleId: 'com.heft.frontend',
  );
}
''';

  File(_outputPath).writeAsStringSync(content);
  stdout.writeln('✓ Generado $_outputPath (project: $projectId)');
}
