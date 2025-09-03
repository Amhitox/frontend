import 'package:dio/dio.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/utils/constants.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  Future<dynamic> getUser(String id) async {
    try {
      final response = await _dio.get('/api/users/$id');
      print('✅ Get user successful');
      return response;
    } on DioException catch (e) {
      print('❌ Get user failed: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> updateUser(String id, User user) async {
    try {
      final response = await _dio.put('api/users/$id', data: user.toJson());
      print('✅ Update user successful');
      return response;
    } on DioException catch (e) {
      print('❌ Update user failed: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> changePassword(String id, String newPassword) async {
    try {
      final response = await _dio.put(
        'api/users/$id/change-password',
        data: {'password': newPassword, 'confirmPassword': newPassword},
      );
      print('✅ Change password successful');
      return response;
    } on DioException catch (e) {
      print('❌ Change password failed: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> deleteUser(String id) async {
    try {
      final response = await _dio.delete('api/users/$id');
      print('✅ Delete user successful');
      return response;
    } on DioException catch (e) {
      print('❌ Delete user failed: ${e.message}');
      rethrow;
    }
  }
}
