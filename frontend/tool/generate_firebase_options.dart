// Genera lib/firebase_options.dart desde:
//   - android/app/google-services.json (obligatorio)
//   - ios/Runner/GoogleService-Info.plist (opcional; recomendado para iOS)
//
// Uso (desde frontend/):
//   dart run tool/generate_firebase_options.dart

import 'dart:convert';
import 'dart:io';

const _packageName = 'com.heft.frontend';
const _iosBundleId = 'com.heft.frontend';
const _googleServicesPath = 'android/app/google-services.json';
const _iosPlistPath = 'ios/Runner/GoogleService-Info.plist';
const _outputPath = 'lib/firebase_options.dart';

void main() {
  final androidFile = File(_googleServicesPath);
  if (!androidFile.existsSync()) {
    stderr.writeln(
      'No se encontró $_googleServicesPath\n'
      'Descárgalo desde Firebase Console → Project settings → Your apps → Android ($_packageName)',
    );
    exit(1);
  }

  final root = jsonDecode(androidFile.readAsStringSync()) as Map<String, dynamic>;
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
  final androidApiKey = apiKeys.first['current_key'] as String;
  final androidAppId = clientInfo['mobilesdk_app_id'] as String;
  final projectId = projectInfo['project_id'] as String;
  final messagingSenderId = projectInfo['project_number'] as String;
  final storageBucket = projectInfo['storage_bucket'] as String;

  var iosApiKey = androidApiKey;
  var iosAppId = androidAppId;
  var iosBundleId = _iosBundleId;

  final plistFile = File(_iosPlistPath);
  if (plistFile.existsSync()) {
    final plist = _parsePlist(plistFile.readAsStringSync());
    iosApiKey = plist['API_KEY'] ?? iosApiKey;
    iosAppId = plist['GOOGLE_APP_ID'] ?? iosAppId;
    iosBundleId = plist['BUNDLE_ID'] ?? iosBundleId;
    stdout.writeln('✓ iOS: $_iosPlistPath');
  } else {
    stderr.writeln(
      'Aviso: sin $_iosPlistPath — iOS usará los mismos valores que Android.\n'
      'Para push en iPhone: añade app iOS en Firebase, descarga GoogleService-Info.plist y vuelve a ejecutar este script.',
    );
  }

  final content = '''
// GENERADO por: dart run tool/generate_firebase_options.dart
// No editar a mano. Fuentes: google-services.json (+ GoogleService-Info.plist si existe)

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '$androidApiKey',
    appId: '$androidAppId',
    messagingSenderId: '$messagingSenderId',
    projectId: '$projectId',
    storageBucket: '$storageBucket',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$androidApiKey',
    appId: '$androidAppId',
    messagingSenderId: '$messagingSenderId',
    projectId: '$projectId',
    storageBucket: '$storageBucket',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '$iosApiKey',
    appId: '$iosAppId',
    messagingSenderId: '$messagingSenderId',
    projectId: '$projectId',
    storageBucket: '$storageBucket',
    iosBundleId: '$iosBundleId',
  );
}
''';

  File(_outputPath).writeAsStringSync(content);
  stdout.writeln('✓ Generado $_outputPath (project: $projectId)');
}

/// Parser mínimo de plist XML (solo strings <key>/<string>).
Map<String, String> _parsePlist(String xml) {
  final result = <String, String>{};
  final keyRe = RegExp(r'<key>([^<]+)</key>\s*<string>([^<]*)</string>');
  for (final match in keyRe.allMatches(xml)) {
    result[match.group(1)!] = match.group(2)!;
  }
  return result;
}
