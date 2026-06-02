import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../firebase_options.dart';
import '../api/api_client.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    return;
  }
  // App already initialized in main when FCM is configured.
}

/// Central service for Firebase Cloud Messaging.
///
/// Call [init] once from main() after [Firebase.initializeApp] succeeds.
/// If Firebase is not configured, all methods no-op safely.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'heft_main_channel';
  static const _androidChannelName = 'Heft Notificaciones';
  static const _androidChannelDesc = 'Recordatorios de entrenamiento y progreso';

  String? _currentToken;
  String? get currentToken => _currentToken;

  bool _ready = false;
  bool get isReady => _ready;

  /// True when [Firebase.initializeApp] completed successfully.
  static bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  /// Firebase configurado en el proyecto (google-services.json + generator).
  static bool get isFirebaseConfigured => DefaultFirebaseOptions.isConfigured;

  FirebaseMessaging? get _messaging =>
      isFirebaseAvailable ? FirebaseMessaging.instance : null;

  Future<void> init() async {
    if (!isFirebaseAvailable) {
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Firebase no inicializado — FCM desactivado. '
          'Añade google-services.json y ejecuta flutterfire configure.',
        );
      }
      return;
    }

    final messaging = _messaging;
    if (messaging == null) return;

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    await _setupLocalNotifications();
    await _requestPermissions(messaging);
    await _loadToken(messaging);
    _listenForegroundMessages();
    _listenTokenRefresh(messaging);
    _ready = true;
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localNotifications.initialize(initSettings);

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDesc,
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Pide permiso del sistema (Android 13+) y de FCM (iOS / fallback).
  Future<AuthorizationStatus> requestPermissions() async {
    if (!isFirebaseConfigured || !isFirebaseAvailable) {
      return AuthorizationStatus.notDetermined;
    }

    final messaging = _messaging;
    if (messaging == null) return AuthorizationStatus.notDetermined;

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!_ready) {
      await _setupLocalNotifications();
      await _loadToken(messaging);
      _listenForegroundMessages();
      _listenTokenRefresh(messaging);
      _ready = true;
    }

    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }
    return settings.authorizationStatus;
  }

  Future<void> _requestPermissions(FirebaseMessaging messaging) async {
    await requestPermissions();
  }

  Future<void> _loadToken(FirebaseMessaging messaging) async {
    try {
      _currentToken = await messaging.getToken();
      if (kDebugMode) debugPrint('FCM token: $_currentToken');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM getToken error: $e');
    }
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  void _listenTokenRefresh(FirebaseMessaging messaging) {
    messaging.onTokenRefresh.listen((newToken) async {
      _currentToken = newToken;
      await registerTokenWithBackend(newToken);
    });
  }

  /// Registers the FCM token with the Heft backend after login.
  Future<void> registerTokenWithBackend(String token) async {
    if (!_ready) return;
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      await apiClient.post(
        'notifications/devices/',
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('Failed to register FCM token: $e');
    }
  }

  /// Marks all device tokens as inactive on logout.
  Future<void> deactivateToken() async {
    if (!_ready || _currentToken == null) return;
    try {
      final response = await apiClient.get('notifications/devices/');
      final List tokens = response.data as List;
      for (final t in tokens) {
        final id = t['id'];
        if (id != null) {
          await apiClient.delete('notifications/devices/$id/');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('Failed to deactivate token: $e');
    }
  }

  /// Returns the current FCM authorization status.
  Future<AuthorizationStatus> getPermissionStatus() async {
    if (!isFirebaseConfigured || !isFirebaseAvailable) {
      return AuthorizationStatus.notDetermined;
    }

    if (Platform.isAndroid) {
      final androidStatus = await Permission.notification.status;
      if (!androidStatus.isGranted) {
        return AuthorizationStatus.denied;
      }
    }

    final messaging = _messaging;
    if (messaging == null) return AuthorizationStatus.notDetermined;

    if (!_ready) {
      return AuthorizationStatus.notDetermined;
    }

    final settings = await messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }
}
