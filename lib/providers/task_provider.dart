import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService task;
  TaskProvider({required Dio dio}) : task = TaskService(dio: dio);

  Future<void> addTask(
    String title,
    String description,
    String priority, {
    String date = "2025-09-01T18:00:00.000Z",
  }) async {
    await task.addTask(title, description, priority);
    notifyListeners();
  }
}
