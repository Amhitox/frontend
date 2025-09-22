import 'package:dio/dio.dart';

class TaskService {
  final Dio _dio;
  static const int CACHE_DAYS = 14;

  TaskService({required Dio dio}) : _dio = dio;

  Future<Response> addTask(
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
      return Response(
        data: e.response?.data ?? {'error': 'Network error'},
        statusCode: e.response?.statusCode ?? 500,
        requestOptions: e.requestOptions,
      );
    }
  }

  Future<Response> getAllTasks() async {
    try {
      final response = await _dio.get("/api/tasks");
      return response;
    } on DioException catch (e) {
      return e.response ??
          Response(
            data: {'error': 'Network error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/tasks'),
          );
    }
  }

  Future<Response> getTasks(String date) async {
    try {
      final response = await _dio.get(
        "/api/tasks",
        queryParameters: {"date": date},
      );
      return response;
    } on DioException catch (e) {
      return e.response ??
          Response(
            data: {'error': 'Network error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/tasks'),
          );
    }
  }

  Future<Response> updateTask(
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
      return Response(
        data: e.response?.data ?? {'error': 'Network error'},
        statusCode: e.response?.statusCode ?? 500,
        requestOptions: e.requestOptions,
      );
    }
  }

  Future<Response> deleteTask(String id) async {
    try {
      final response = await _dio.delete('/api/tasks/$id');
      return response;
    } on DioException catch (e) {
      return Response(
        data: e.response?.data ?? {'error': 'Network error'},
        statusCode: e.response?.statusCode ?? 500,
        requestOptions: e.requestOptions,
      );
    }
  }
}
