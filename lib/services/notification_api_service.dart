import 'package:dio/dio.dart';
import 'package:frontend/models/notification_model.dart';

class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  Future<List<AppNotification>> getNotifications({
    required String userId,
    String filter = 'all',
  }) async {
    try {
      final response = await _dio.get(
        '/api/notifications',
        queryParameters: {
          'userId': userId,
          'filter': filter,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> list = [];
        if (data is Map && data.containsKey('notifications')) {
          list = data['notifications'];
        } else if (data is List) {
          list = data;
        }
        
        return list.map((json) => AppNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw e;
    }
  }

  Future<void> markAsRead({
    required String userId,
    String? notificationId,
    bool markAll = false,
  }) async {
    try {
      await _dio.patch(
        '/api/notifications',
        queryParameters: {
          'userId': userId,
          if (notificationId != null) 'id': notificationId,
          if (markAll) 'all': 'true',
        },
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteNotification({
    required String userId,
    String? notificationId,
    bool deleteAll = false,
  }) async {
    try {
      await _dio.delete(
        '/api/notifications',
        queryParameters: {
          'userId': userId,
          if (notificationId != null) 'id': notificationId,
          if (deleteAll) 'all': 'true',
        },
      );
    } catch (e) {
      throw e;
    }
  }
}
