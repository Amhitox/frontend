import 'package:flutter/foundation.dart';
import 'package:frontend/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class TaskManager {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();

  late Box<Task> _box;

  Future<void> init(String userId) async {
    _box = await Hive.openBox<Task>('tasks_$userId');
  }

  Future<void> addOrUpdateTask(Task task) async {
    task.id ??= const Uuid().v4();
    await _box.put(task.id, task);
  }

  List<Task> getTaskOfDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T').first;
    return _box!.values
        .where((t) => t.dueDate?.split('T').first == dateStr)
        .toList();
  }

  ValueListenable<Box<Task>> listenable() => _box.listenable();

  Future<List<Task>> getAllUnsyncedTasks() async {
    return _box.values.where((t) => t.id == '1').toList();
  }

  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAllTasks() async {
    await _box.clear();
  }
}
