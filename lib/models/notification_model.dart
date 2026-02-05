enum NotificationType { email, task, event, calendar, system, unknown }

enum NotificationPriority { high, normal, low }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message; // Maps to 'body'
  final String time; // Maps to 'sentAt'
  final NotificationType type;
  bool isRead; // Maps to 'read'
  final bool deleted;
  final String status; // 'sent' | 'failed' | 'delivered'
  final Map<String, dynamic>? metadata;
  final NotificationPriority
  priority; // Not in backend type, will infer or default

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
    this.deleted = false,
    this.status = 'sent',
    this.metadata,
    this.priority = NotificationPriority.normal,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? 'No Title',
      message: json['body'] ?? '',
      time: json['sentAt'] ?? DateTime.now().toIso8601String(),
      type: _parseType(json['type']),
      isRead: json['read'] ?? false,
      deleted: json['deleted'] ?? false,
      status: json['status'] ?? 'sent',
      metadata:
          json['data'] ??
          json['metadata'], // Maps 'data' from backend to 'metadata' property
      // Infer priority from metadata or default to normal since it's not in the main type
      priority: _inferPriority(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': message,
      'sentAt': time,
      'status': status,
      'read': isRead,
      'deleted': deleted,
      'metadata': metadata,
    };
  }

  static NotificationType _parseType(String? type) {
    if (type == null) return NotificationType.system;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == type.toLowerCase(),
        orElse: () => NotificationType.unknown,
      );
    } catch (_) {
      return NotificationType.unknown;
    }
  }

  static NotificationPriority _inferPriority(Map<String, dynamic> json) {
    // Basic inference or checking metadata
    if (json['metadata'] != null && json['metadata']['priority'] != null) {
      try {
        return NotificationPriority.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              json['metadata']['priority'].toString().toLowerCase(),
          orElse: () => NotificationPriority.normal,
        );
      } catch (_) {
        return NotificationPriority.normal;
      }
    }
    return NotificationPriority.normal;
  }
}
