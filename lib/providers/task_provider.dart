import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService task;
  TaskProvider({required Dio dio}) : task = TaskService(dio: dio);
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> addTask(
    String title,
    String description,
    String priority, {
    String date = "2025-09-01T18:00:00.000Z",
  }) async {
    await task.addTask(title, description, priority);
    notifyListeners();
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
}
