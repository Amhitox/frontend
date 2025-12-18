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
    if (id == null || id.isEmpty) {
        throw DioException(
           requestOptions: RequestOptions(path: '/api/users/'), 
           error: 'User ID is missing for update'
        );
    }
    try {
      final data = {
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'lang': user.lang,
      };
      if (user.workEmail != null) {
        data['workEmail'] = user.workEmail;
      }
      final response = await _dio.put('/api/users/$id', data: data);
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
  Future<List<String>> getPriorityEmails(String userId) async {
    try {
      final response = await _dio.get(
        '/api/settings/priority-emails',
        queryParameters: {'userId': userId},
      );
      if (response.data != null && response.data['priorityEmails'] != null) {
        return List<String>.from(response.data['priorityEmails']);
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<void> addPriorityEmail(String userId, String email) async {
    try {
      await _dio.post(
        '/api/settings/priority-emails',
        data: {'userId': userId, 'email': email},
      );
    } on DioException {
      rethrow;
    }
  }

  Future<void> removePriorityEmail(String userId, String email) async {
    try {
      await _dio.delete(
        '/api/settings/priority-emails',
        queryParameters: {'userId': userId, 'email': email},
      );
    } on DioException {
      rethrow;
    }
  }
}
