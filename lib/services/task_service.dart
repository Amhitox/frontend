import 'package:dio/dio.dart';

class TaskService {
  final Dio _dio;
  // ignore: constant_identifier_names
  static const int CACHE_DAYS = 14;

  TaskService({required Dio dio}) : _dio = dio;

  Future<dynamic> addTask(
    String title,
    String description,
    String priority,
    String dueDate,
    bool isCompleted,
    String category,
  ) async {
    try {
      final response = await _dio.post(
        "/api/tasks",
        data: {
          "title": title,
          "description": description,
          "priority": priority,
          "category": category,
          "dueDate": dueDate,
          "isCompleted": isCompleted,
        },
      );
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<dynamic> getTasks(String date) async {
    try {
      final response = await _dio.get(
        "/api/tasks",
        queryParameters: {"date": date},
      );
      print(response.data);
      print("got tasks");
      return response;
    } on DioException catch (e) {
      print('Task failed: ${e.response?.statusCode} ${e.response?.data}');
      return e.response;
    }
  }

  Future<dynamic> updateTask(
    String id,
    String? title,
    String? description,
    String? priority,
    String? dueDate,
    bool? isCompleted,
    String? category,
  ) async {
    try {
      Map<String, dynamic> data = {
        "title": title,
        "description": description,
        "priority": priority,
        "dueDate": dueDate,
        "isCompleted": isCompleted,
        "category": category,
      };

      data.removeWhere((key, value) => value == null);

      final response = await _dio.patch('/api/tasks/$id', data: data);
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<dynamic> deleteTask(String id) async {
    try {
      final response = await _dio.delete('/api/tasks/$id');
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }
}
