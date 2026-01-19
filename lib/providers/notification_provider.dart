import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:frontend/services/notification_api_service.dart';
import 'package:frontend/services/notification_service.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _apiService;
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  NotificationProvider({required Dio dio}) : _apiService = NotificationApiService(dio);

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _subscription;

  void init(String userId) {
    _userId = userId;
    fetchNotifications();
    
    _subscription?.cancel();
    _subscription = NotificationService().messageStream.listen((message) {
      // When a new notification arrives, refresh the list
      fetchNotifications(forceRefresh: true);
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications({String filter = 'all', bool forceRefresh = false}) async {
    if (_userId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _apiService.getNotifications(
        userId: _userId!,
        filter: filter,
      );
    } on DioException catch (e) {
      _error = e.toString(); // Keep generic for UI for now, or map it
      print('Error fetching notifications: ${e.message}');
      if (e.response != null) {
        print('Server error data: ${e.response?.data}');
        print('Server error headers: ${e.response?.headers}');
        print('Request data: ${e.requestOptions.data}');
        print('Request query parameters: ${e.requestOptions.queryParameters}');
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    if (_userId == null) return;
    
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }

    try {
      await _apiService.markAsRead(userId: _userId!, notificationId: id);
    } catch (e) {
      // Revert if failed
      if (index != -1) {
        _notifications[index].isRead = false;
        notifyListeners();
      }
      print('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    final previousState = _notifications.map((n) => n.isRead).toList();
    
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    try {
      await _apiService.markAsRead(userId: _userId!, markAll: true);
    } catch (e) {
      // Revert
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i].isRead = previousState[i];
      }
      notifyListeners();
      print('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    if (_userId == null) return;

    final notification = _notifications.firstWhere((n) => n.id == id, orElse: () => AppNotification(id: '', userId: '', title: '', message: '', time: '', type: NotificationType.system, isRead: false, priority: NotificationPriority.low));
    if (notification.id.isEmpty) return;

    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();

    try {
      await _apiService.deleteNotification(userId: _userId!, notificationId: id);
    } catch (e) {
      // Revert
      _notifications.add(notification);
      // Sort might be needed here to put it back in place
      notifyListeners();
      print('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    if (_userId == null) return;

    final previousList = List<AppNotification>.from(_notifications);
    _notifications.clear();
    notifyListeners();

    try {
      await _apiService.deleteNotification(userId: _userId!, deleteAll: true);
    } catch (e) {
      _notifications = previousList;
      notifyListeners();
      print('Error clearing notifications: $e');
    }
  }
}
