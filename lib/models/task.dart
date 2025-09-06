import 'taskpriority.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  TaskPriority priority;
  bool isCompleted;
  String dueTime;
  final String status;
  final bool reminderSent;
  final String visibility;
  final String recurrence;
  final List<String> tags;
  final List<String> attachments;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.isCompleted,
    required this.dueTime,
    required this.status,
    required this.reminderSent,
    required this.visibility,
    required this.recurrence,
    required this.tags,
    required this.attachments,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Task object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority':
          priority.toString().split('.').last, // Converts enum to string
      'isCompleted': isCompleted,
      'dueDate': dueTime,
      'status': status,
      'reminderSent': reminderSent,
      'visibility': visibility,
      'recurrence': recurrence,
      'tags': tags,
      'attachments': attachments,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Task object from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category:
          json['category'] ??
          '', // You might want to derive this from tags or set a default
      priority: _parsePriority(json['priority']),
      isCompleted: json['isCompleted'] ?? false,
      dueTime: json['dueDate'] ?? '',
      status: json['status'] ?? 'pending',
      reminderSent: json['reminderSent'] ?? false,
      visibility: json['visibility'] ?? 'private',
      recurrence: json['recurrence'] ?? 'none',
      tags: List<String>.from(json['tags'] ?? []),
      attachments: List<String>.from(json['attachments'] ?? []),
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Helper method to parse priority string to TaskPriority enum
  static TaskPriority _parsePriority(String? priorityString) {
    switch (priorityString?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.low; // Default to low priority
    }
  }

  // Helper method to create a copy of the task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    TaskPriority? priority,
    bool? isCompleted,
    String? dueTime,
    String? status,
    bool? reminderSent,
    String? visibility,
    String? recurrence,
    List<String>? tags,
    List<String>? attachments,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      dueTime: dueTime ?? this.dueTime,
      status: status ?? this.status,
      reminderSent: reminderSent ?? this.reminderSent,
      visibility: visibility ?? this.visibility,
      recurrence: recurrence ?? this.recurrence,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
