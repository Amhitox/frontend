import 'package:dio/dio.dart';
import 'package:frontend/models/user.dart';

class UserService {
  final Dio _dio;
  UserService({required Dio dio}) : _dio = dio;
  Future<dynamic> getUser(String id) async {
    try {
      final response = await _dio.get('/api/users/$id');
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<dynamic> updateUser(String? id, User user) async {
    try {
      final response = await _dio.put('/api/users/$id', data: user.toJson());
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<dynamic> changePassword(String id, String newPassword) async {
    try {
      final response = await _dio.put(
        '/api/users/$id/change-password',
        data: {'password': newPassword, 'confirmPassword': newPassword},
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<dynamic> deleteUser(String id) async {
    try {
      final response = await _dio.delete('/api/users/$id');
      return response;
    } on DioException {
      rethrow;
    }
  }
}
