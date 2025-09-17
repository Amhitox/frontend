import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService task;
  TaskProvider({required Dio dio}) : task = TaskService(dio: dio);
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<String> addTask(
    String title,
    String description,
    String priority,
    String dueDate,
    bool isCompleted,
    String category,
  ) async {
    try {
      final response = await task.addTask(
        title,
        description,
        priority,
        dueDate,
        isCompleted,
        category,
      );
      if (response.statusCode == 201) {
        print('task added success');
        return response.data["taskId"];
      }
      notifyListeners();
      return '';
    } catch (e) {
      print('task added failed');
      return '';
    }
  }

  Future<List<Task>> getTasks() async {
    _isLoading = true;
    notifyListeners();
    final response = await task.getTasks();
    late List<Task> tasks;
    if (response.statusCode == 200) {
      List<dynamic> jsonList = response.data["data"] as List<dynamic>;
      tasks = jsonList.map((json) => Task.fromJson(json)).toList();
    }
    _isLoading = false;
    notifyListeners();
    return tasks;
  }

  Future<void> updateTask({
    required String id,
    String? title,
    String? description,
    String? priority,
    String? dueDate,
    bool? isCompleted,
    String? category,
  }) async {
    await task.updateTask(
      id,
      title,
      description,
      priority,
      dueDate,
      isCompleted,
      category,
    );
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await task.deleteTask(id);
    notifyListeners();
  }
}
