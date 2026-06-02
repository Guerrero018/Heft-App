import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/api_client.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Central service for Firebase Cloud Messaging.
///
/// Call [init] once from main() after Firebase.initializeApp().
/// Call [registerTokenWithBackend] after the user logs in.
/// Call [deactivateToken] on logout.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'heft_main_channel';
  static const _androidChannelName = 'Heft Notificaciones';
  static const _androidChannelDesc = 'Recordatorios de entrenamiento y progreso';

  String? _currentToken;
  String? get currentToken => _currentToken;

  bool _ready = false;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await _setupLocalNotifications();
    await _requestPermissions();
    await _loadToken();
    _listenForegroundMessages();
    _listenTokenRefresh();
    _ready = true;
  }

  // -------------------------------------------------------------------------
  // Setup
  // -------------------------------------------------------------------------

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

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint(
        'FCM permission: ${settings.authorizationStatus}',
      );
    }
  }

  Future<void> _loadToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (kDebugMode) debugPrint('FCM token: $_currentToken');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM getToken error: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Listeners
  // -------------------------------------------------------------------------

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

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      _currentToken = newToken;
      await registerTokenWithBackend(newToken);
    });
  }

  // -------------------------------------------------------------------------
  // Token registration
  // -------------------------------------------------------------------------

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
    if (!_ready) return AuthorizationStatus.notDetermined;
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }
}
