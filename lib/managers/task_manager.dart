import 'package:flutter/foundation.dart';
import 'package:frontend/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
class TaskManager {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();
  Box<Task>? _box;
  Box<String>? _syncBox;
  Box<String>? _deletedBox; 
  Future<void> init(String userId) async {
    _box = await Hive.openBox<Task>('tasks_$userId');
    _syncBox = await Hive.openBox<String>('sync_status_$userId');
    _deletedBox = await Hive.openBox<String>('deleted_tasks_$userId');
  }
  bool get isInitialized =>
      _box != null && _syncBox != null && _deletedBox != null;
  Future<void> addOrUpdateTask(Task task, {bool isSynced = false}) async {
    if (!isInitialized) {
      throw Exception('TaskManager not initialized. Call init() first.');
    }
    await _box!.put(task.id, task);
    await _syncBox!.put('${task.id}_synced', isSynced.toString());
  }
  Future<void> markTaskAsSynced(String taskId) async {
    if (!isInitialized) return;
    await _syncBox!.put('${taskId}_synced', 'true');
  }
  List<Task> getTaskOfDate(DateTime date) {
    if (!isInitialized) {
      return [];
    }
    final dateStr = date.toIso8601String().split('T').first;
    return _box!.values
        .where((t) => t.dueDate?.split('T').first == dateStr)
        .toList();
  }
  ValueListenable<Box<Task>>? listenable() {
    if (!isInitialized) {
      return null;
    }
    return _box!.listenable();
  }
  List<Task> getAllUnsyncedTasks() {
    if (!isInitialized) {
      return [];
    }
    return _box!.values.where((task) {
      final syncStatus = _syncBox!.get('${task.id}_synced');
      return syncStatus != 'true';
    }).toList();
  }
  List<Task> getAllTasks() {
    if (!isInitialized) {
      return [];
    }
    return _box!.values.toList();
  }
  Task? getTaskById(String id) {
    if (!isInitialized) {
      return null;
    }
    return _box!.get(id);
  }
  bool isTaskSynced(String taskId) {
    if (!isInitialized) return false;
    final syncStatus = _syncBox!.get('${taskId}_synced');
    return syncStatus == 'true';
  }
  Future<void> deleteTask(String id) async {
    if (!isInitialized) {
      throw Exception('TaskManager not initialized. Call init() first.');
    }
    final wasSynced = _syncBox!.get('${id}_synced') == 'true';
    if (wasSynced) {
      await _deletedBox!.put('deleted_$id', id);
    }
    await _box!.delete(id);
    await _syncBox!.delete('${id}_synced');
  }
  List<String> getDeletedTasks() {
    if (!isInitialized) {
      return [];
    }
    return _deletedBox!.values.toList();
  }
  Future<void> clearDeletedTask(String taskId) async {
    if (!isInitialized) return;
    await _deletedBox!.delete('deleted_$taskId');
  }
  Future<void> clearAllTasks() async {
    if (!isInitialized) {
      throw Exception('TaskManager not initialized. Call init() first.');
    }
    await _box!.clear();
    await _syncBox!.clear();
    await _deletedBox!.clear();
  }
  Future<void> syncTasksFromServer(List<Task> serverTasks) async {
    if (!isInitialized) return;
    for (final task in serverTasks) {
      await addOrUpdateTask(task, isSynced: true);
    }
  }
  Future<void> updateTaskFromServer(Task task) async {
    if (!isInitialized) return;
    await addOrUpdateTask(task, isSynced: true);
  }
}
