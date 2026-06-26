import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Local notifications setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel (Android 8+)
    await _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'alzheimer_channel',
          'Alzheimer Assistant',
          description: 'Medicine reminders and GPS alerts',
          importance: Importance.max,
        ));

    // Skip Firebase Messaging on web platform
    if (kIsWeb) return;

    // Firebase Messaging setup (mobile only)
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );

      // Get FCM token and save to server
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        try { await ApiService.updateFcmToken(token); } catch (_) {}
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try { await ApiService.updateFcmToken(newToken); } catch (_) {}
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        _showLocalNotification(message);
      });

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationData(message.data);
      });
    } catch (e) {
      print('Firebase Messaging setup failed: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle local notification tap if needed
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alzheimer_channel',
          'Alzheimer Assistant',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  static void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == 'gps_alert') {
      // Navigate to GPS screen — handled by navigator key
    } else if (type == 'medicine_alert') {
      // Navigate to medications screen
    }
  }

  /// Show a local notification directly (for testing)
  static Future<void> showTestNotification(String title, String body) async {
    await _local.show(
      0, title, body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alzheimer_channel', 'Alzheimer Assistant',
          importance: Importance.max, priority: Priority.high,
        ),
      ),
    );
  }
}

/// Background message handler — must be top-level function
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the OS notification tray
  // No action needed here unless you want to update local DB
}
