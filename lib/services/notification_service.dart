import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android (required for Android 8.0+)
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _isInitialized = true;
    debugPrint('✅ Notification service initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // You can add navigation logic here based on the payload
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int notificationId = 0,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle foreground FCM messages
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message received: ${message.messageId}');
    
    // Extract notification data
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await showNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: data.toString(),
        notificationId: message.hashCode,
      );
    } else if (data.isNotEmpty) {
      // Handle data-only messages
      final title = data['title'] ?? 'New Notification';
      final body = data['body'] ?? data['message'] ?? '';
      
      await showNotification(
        title: title.toString(),
        body: body.toString(),
        payload: data.toString(),
        notificationId: message.hashCode,
      );
    }
  }
}

