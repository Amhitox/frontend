import 'taskpriority.dart';

class Task {
  final String title;
  final String description;
  final String category;
  TaskPriority priority;
  bool isCompleted;
  String dueTime;

  Task({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.isCompleted,
    required this.dueTime,
  });
}
