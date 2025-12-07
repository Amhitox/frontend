import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/models/taskpriority.dart';
import 'package:frontend/services/task_service.dart';
import 'package:frontend/managers/task_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class TaskProvider extends ChangeNotifier {
  final TaskService task;
  final TaskManager _taskManager = TaskManager();
  TaskProvider({required Dio dio}) : task = TaskService(dio: dio);

  bool _isLoading = false;
  bool _isOnline = true;
  bool _isSyncing = false;
  bool _syncInProgress = false;
  DateTime? _lastSyncTime;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final Set<String> _syncingTasks = <String>{};

  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  Future<void> init(String userId) async {
    await _taskManager.init(userId);
    _checkConnectivity();
    _startConnectivityMonitoring();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);

      print(
        'TaskProvider: Connectivity changed - Online: $_isOnline, Was offline: $wasOffline',
      );

      if (wasOffline && _isOnline && !_syncInProgress) {
        final now = DateTime.now();
        if (_lastSyncTime == null ||
            now.difference(_lastSyncTime!).inSeconds > 10) {
          print('TaskProvider: Scheduling sync in 2 seconds');
          Timer(const Duration(seconds: 2), () {
            if (_isOnline && !_syncInProgress) {
              print('TaskProvider: Starting full sync');
              _performFullSync();
            }
          });
        }
      }

      notifyListeners();
    });
  }

  Future<void> _performFullSync() async {
    if (!_isOnline || _syncInProgress) {
      print(
        'TaskProvider: Sync skipped - offline: ${!_isOnline}, in progress: $_syncInProgress',
      );
      return;
    }

    print('TaskProvider: Starting full sync process');
    _syncInProgress = true;
    _isSyncing = true;
    _lastSyncTime = DateTime.now();
    notifyListeners();

    try {
      print('TaskProvider: Syncing deleted tasks');
      await _syncDeletedTasks();

      print('TaskProvider: Syncing unsynced tasks');
      await syncUnsyncedTasks();

      print('TaskProvider: Syncing from server');
      await syncAllFromServer();

      print('TaskProvider: Full sync completed successfully');
    } catch (e) {
      print('TaskProvider: Full sync failed: $e');
    } finally {
      _isSyncing = false;
      _syncInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _syncDeletedTasks() async {
    final deletedTasks = _taskManager.getDeletedTasks();

    for (final taskId in deletedTasks) {
      try {
        await task.deleteTask(taskId);
        await _taskManager.clearDeletedTask(taskId);
      } catch (e) {}
    }
  }

  void _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult.any(
      (result) => result != ConnectivityResult.none,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<String> addTask(
    String title,
    String description,
    String priority,
    DateTime date,
    TimeOfDay time,
    bool isCompleted,
    String category,
  ) async {
    String taskId;

    // Combine date and time for API
    final combinedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final timezoneOffset = _formatTimezoneOffset(
      combinedDateTime.timeZoneOffset,
    );

    if (_isOnline) {
      try {
        final response = await task.addTask(
          title,
          description,
          priority,
          combinedDateTime.toIso8601String(),
          isCompleted,
          category,
          timezoneOffset,
        );

        if (response.statusCode == 201) {
          taskId = response.data["taskId"];

          final newTask = Task(
            id: taskId,
            title: title,
            description: description,
            priority: _parsePriority(priority),
            dueDate: combinedDateTime.toIso8601String(),
            isCompleted: isCompleted,
            category: category,
          );

          await _taskManager.addOrUpdateTask(newTask, isSynced: true);
        } else {
          throw Exception('Server returned status: ${response.statusCode}');
        }
      } catch (e) {
        taskId = await _createLocalTask(
          title,
          description,
          priority,
          date,
          time,
          isCompleted,
          category,
        );
      }
    } else {
      taskId = await _createLocalTask(
        title,
        description,
        priority,
        date,
        time,
        isCompleted,
        category,
      );
    }

    notifyListeners();
    return taskId;
  }

  Future<String> _createLocalTask(
    String title,
    String description,
    String priority,
    DateTime date,
    TimeOfDay time,
    bool isCompleted,
    String category,
  ) async {
    final combinedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final newTask = Task(
      id: null,
      title: title,
      description: description,
      priority: _parsePriority(priority),
      dueDate: combinedDateTime.toIso8601String(),
      isCompleted: isCompleted,
      category: category,
    );

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final taskWithTempId = newTask.copyWith(id: tempId);

    await _taskManager.addOrUpdateTask(taskWithTempId, isSynced: false);
    return tempId;
  }

  TaskPriority _parsePriority(String priorityString) {
    switch (priorityString.toLowerCase()) {
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

  Future<List<Task>> getTasks(String date) async {
    _isLoading = true;
    notifyListeners();

    final localTasks = _taskManager.getTaskOfDate(DateTime.parse(date));

    _isLoading = false;
    notifyListeners();
    return localTasks;
  }

  Future<void> syncAllFromServer() async {
    if (!_isOnline) return;

    try {
      print('TaskProvider: Syncing all tasks from server');
      final response = await task.getAllTasks();

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data != null && data["tasks"] != null) {
          final jsonList = data["tasks"] as List<dynamic>;
          final serverTasks =
              jsonList.map((json) => Task.fromJson(json)).toList();

          print(
            'TaskProvider: Fetched ${serverTasks.length} tasks from server',
          );
          await _taskManager.syncTasksFromServer(serverTasks);
          notifyListeners();
        }
      }
    } catch (e) {
      print('TaskProvider: Error in syncAllFromServer: $e');
    }
  }



  Future<void> updateTask({
    required String id,
    String? title,
    String? description,
    String? priority,
    DateTime? date,
    TimeOfDay? time,
    bool? isCompleted,
    String? category,
  }) async {
    final existingTask = _taskManager.getTaskById(id);
    if (existingTask == null) return;

    // Combine date and time if both are provided
    String? combinedDueDate;
    if (date != null && time != null) {
      final combinedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      combinedDueDate = combinedDateTime.toIso8601String();
    }

    final updatedTask = existingTask.copyWith(
      title: title,
      description: description,
      priority: priority != null ? _parsePriority(priority) : null,
      dueDate: combinedDueDate,
      isCompleted: isCompleted,
      category: category,
    );

    // Skip API call for temp IDs - they don't exist on the server yet
    final isTempId = id.startsWith('temp_');

    if (_isOnline && !isTempId) {
      try {
        await task.updateTask(
          id,
          title,
          description,
          priority,
          combinedDueDate ?? existingTask.dueDate,
          isCompleted,
          category,
        );

        await _taskManager.addOrUpdateTask(updatedTask, isSynced: true);
      } catch (e) {
        await _taskManager.addOrUpdateTask(updatedTask, isSynced: false);
      }
    } else {
      // For temp IDs or offline, just update locally
      await _taskManager.addOrUpdateTask(updatedTask, isSynced: false);
    }

    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    if (_isOnline) {
      try {
        await task.deleteTask(id);
        await _taskManager.deleteTask(id);
      } catch (e) {
        await _taskManager.deleteTask(id);
      }
    } else {
      await _taskManager.deleteTask(id);
    }

    notifyListeners();
  }

  Future<void> syncUnsyncedTasks() async {
    if (!_isOnline) {
      return;
    }

    final unsyncedTasks = _taskManager.getAllUnsyncedTasks();

    final List<Task> tempTasks = [];
    final List<Task> existingTasks = [];

    for (final task in unsyncedTasks) {
      if (task.id!.startsWith('temp_')) {
        tempTasks.add(task);
      } else {
        existingTasks.add(task);
      }
    }

    for (final task in tempTasks) {
      if (_syncingTasks.contains(task.id!)) {
        continue;
      }

      _syncingTasks.add(task.id!);

      try {
        // Calculate timezone offset from the task's due date
        String timezoneOffset = '+00:00'; // Default fallback
        if (task.dueDate != null && task.dueDate!.isNotEmpty) {
          try {
            final dueDateTime = DateTime.parse(task.dueDate!);
            timezoneOffset = _formatTimezoneOffset(dueDateTime.timeZoneOffset);
          } catch (e) {
            // If parsing fails, use current timezone
            timezoneOffset = _formatTimezoneOffset(
              DateTime.now().timeZoneOffset,
            );
          }
        } else {
          timezoneOffset = _formatTimezoneOffset(DateTime.now().timeZoneOffset);
        }

        final response = await this.task.addTask(
          task.title ?? '',
          task.description ?? '',
          task.priority!.toString().split('.').last,
          task.dueDate ?? '',
          task.isCompleted ?? false,
          task.category ?? '',
          timezoneOffset,
        );

        if (response.statusCode == 201) {
          final serverTaskId = response.data["taskId"];

          await _taskManager.deleteTask(task.id!);
          final updatedTask = task.copyWith(id: serverTaskId);
          await _taskManager.addOrUpdateTask(updatedTask, isSynced: true);
        } else {}
      } finally {
        _syncingTasks.remove(task.id!);
      }
    }

    for (final task in existingTasks) {
      if (_syncingTasks.contains(task.id!)) {
        continue;
      }

      _syncingTasks.add(task.id!);

      try {
        await this.task.updateTask(
          task.id!,
          task.title,
          task.description,
          task.priority!.toString().split('.').last,
          task.dueDate,
          task.isCompleted,
          task.category,
        );
        await _taskManager.markTaskAsSynced(task.id!);
      } finally {
        _syncingTasks.remove(task.id!);
      }
    }
  }

  Future<void> onConnectivityChanged() async {
    print('TaskProvider: onConnectivityChanged called');
    _checkConnectivity();
    if (_isOnline && !_syncInProgress) {
      print('TaskProvider: Online and not syncing, scheduling sync');
      Timer(const Duration(seconds: 1), () {
        if (_isOnline && !_syncInProgress) {
          print('TaskProvider: Timer triggered, starting sync');
          _performFullSync();
        }
      });
    } else {
      print(
        'TaskProvider: Not syncing - Online: $_isOnline, In progress: $_syncInProgress',
      );
    }
  }

  void debugSyncStatus() {}

  Future<void> forceSync() async {
    _checkConnectivity();
    if (_isOnline && !_syncInProgress) {
      await _performFullSync();
    } else if (_syncInProgress) {
    } else {}
  }

  /// Format timezone offset as "+05:30" or "-05:00"
  String _formatTimezoneOffset(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes.remainder(60).abs();
    final sign = totalMinutes >= 0 ? '+' : '-';
    return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
