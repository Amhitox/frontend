import 'package:dio/dio.dart';

class TaskService {
  final Dio _dio;
  TaskService({required Dio dio}) : _dio = dio;

  Future<dynamic> addTask(
    String title,
    String description,
    String priority, {
    String dueDate = "2025-09-30T18:00:00.000Z",
  }) async {
    try {
      final response = await _dio.post(
        "/api/tasks",
        data: {
          "title": title,
          "description": description,
          "priority": priority,
          "dueDate": dueDate,
        },
      );
      print('task added success');
      return response;
    } on DioException catch (e) {
      print('Task failed: ${e.response?.statusCode} ${e.response?.data}');
      return e.response;
    }
  }

  Future<dynamic> getTasks() async {
    try {
      final response = await _dio.get("/api/tasks");
      print(response.data);
      print("got tasks");
      return response;
    } on DioException catch (e) {
      print('Task failed: ${e.response?.statusCode} ${e.response?.data}');
      return e.response;
    }
  }
}
