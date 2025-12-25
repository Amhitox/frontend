import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:frontend/ui/widgets/top_notification_overlay.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/mail_service.dart';
import 'package:frontend/models/email_message.dart';

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
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    
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
  void _onNotificationTapped(NotificationResponse response) async {
    debugPrint('📱 Notification tapped: ${response.payload}');
    
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!);
      // The payload structure depends on how we send it. 
      // Assuming flat map or 'data' key.
      // If we used jsonEncode(message.data), then fields are top level.
      
      final type = data['type'];
      final context = AppRoutes.navigatorKey.currentContext;

      if (context == null) {
        debugPrint('❌ Navigator context is null');
        return;
      }

      if (type == 'email') {
        final emailId = data['id'] ?? data['emailId'];
        if (emailId != null) {
           final authProvider = context.read<AuthProvider>();
           final mailService = MailService(dio: authProvider.dio);
           
           // Ideally show a loading indicator or route to an intermediate "loading" screen, 
           // but for now we fetch then navigate. 
           // If app was killed, this might happen during splash? No, user tapped notification.
           
           try {
             final emailDetails = await mailService.getEmailDetails(emailId);
             if (emailDetails != null) {
                final email = EmailMessage.fromJson(emailDetails);
                if (context.mounted) {
                    context.pushNamed('maildetail', extra: email);
                }
             }
           } catch (e) {
             debugPrint('❌ Failed to fetch email details for notification: $e');
             if (context.mounted) {
               context.pushNamed('mail');
             }
           }
        } else {
             context.pushNamed('mail');
        }
      } else if (type == 'task') {
        context.pushNamed('task'); // Can pass extras if needed
      } else if (type == 'event') {
        context.pushNamed('calendar');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
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

  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageController.stream;

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message received: ${message.messageId}');
    
    _messageController.add(message);

    final notification = message.notification;
    final data = message.data;

    // Check for Priority Email Payload or audio URL
    final isPriority = data['priority'] == 'true' || data['priority'] == true;
    final type = data['notificationType'] ?? data['type'];
    final audioUrl = data['audioUrl'];
    
    debugPrint('🔔 Foreground notification - type: $type, isPriority: $isPriority, audioUrl: $audioUrl');
    debugPrint('🔔 Full data: $data');
    
    // Show popup for emails that are priority OR have an audio summary
    final shouldShowPopup = (type == 'email_new' || type == 'email') && (isPriority || audioUrl != null);
    
    debugPrint('🔔 shouldShowPopup: $shouldShowPopup');
    
    if (shouldShowPopup) {
       final context = AppRoutes.navigatorKey.currentContext;
       debugPrint('🔔 Context available: ${context != null}');
       if (context != null) {
          final title = data['title'] ?? 'New Email';
          final body = data['body'] ?? 'You have a new message';
          
          debugPrint('🔔 Showing popup with title: $title, body: $body');
          showTopNotification(
            context: context,
            title: title,
            body: body,
            onPlay: audioUrl != null ? () {
                    final emailId = data['emailId'] ?? data['id'];
                    if (emailId != null) {
                         // Create stub
                         final stubEmail = EmailMessage(
                            id: emailId, 
                            threadId: '', 
                            sender: title, 
                            senderEmail: '', 
                            subject: body.toString().split('\n').first, 
                            snippet: '', 
                            body: '', 
                            date: DateTime.now(), 
                            isUnread: true, 
                            labelIds: [], 
                            hasAttachments: false,
                         );
                         
                         final extra = {
                           'email': stubEmail,
                           'audioUrl': audioUrl,
                           'autoPlay': true,
                         };
                         context.push(AppRoutes.maildetail, extra: extra);
                    }
            } : null,
          );
          return; // Skip standard notification
       }
    }

    if (notification != null) {
      await showNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: jsonEncode(data),
        notificationId: message.hashCode,
      );
    } else if (data.isNotEmpty) {
      final title = data['title'] ?? 'New Notification';
      final body = data['body'] ?? data['message'] ?? '';
      
      await showNotification(
        title: title.toString(),
        body: body.toString(),
        payload: jsonEncode(data),
        notificationId: message.hashCode,
      );
    }
  }

  void dispose() {
    _messageController.close();
  }
}

