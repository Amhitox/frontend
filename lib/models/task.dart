import 'package:hive_flutter/hive_flutter.dart';

import 'taskpriority.dart';
part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  final String? title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  String? dueDate;

  @HiveField(4)
  final String? category;

  @HiveField(5)
  TaskPriority? priority;

  @HiveField(6)
  bool? isCompleted;

  Task({
    this.id,
    this.title,
    this.description,
    this.category,
    this.priority,
    this.isCompleted,
    this.dueDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.toString().split('.').last,
      'isCompleted': isCompleted,
      'dueDate': dueDate,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: _parsePriority(json['priority']),
      isCompleted: _parseBool(json['isCompleted']),
      dueDate: json['dueDate'] ?? '',
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is int) {
      return value != 0;
    }
    return null;
  }

  static TaskPriority _parsePriority(String? priorityString) {
    switch (priorityString?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.low;
    }
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    TaskPriority? priority,
    bool? isCompleted,
    String? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
