import 'package:dio/dio.dart';
import 'package:frontend/utils/constants.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  Future<dynamic> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      print('✅ Login successful');
      return response;
    } on DioException catch (e) {
      print('❌ Login failed: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> register(
    String email,
    String password,
    String firstName,
    String lastName,
    String phone,
    String dateOfBirth,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          // 'phone': phone,
          // 'dateOfBirth': dateOfBirth,
        },
      );
      return response;
    } on DioException catch (e) {
      print('❌ Register failed: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> logout() async {
    try {
      final response = await _dio.post('/api/auth/logout');
      print('Logout successfully');
      return response;
    } catch (e) {
      print('Logout failed');
      rethrow;
    }
  }
}
