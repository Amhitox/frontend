import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio;
  AuthService({required Dio dio}) : _dio = dio;

  Future<dynamic> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      print('✅ Login successful');
      return response;
    } on DioException catch (e) {
      print('❌ Login failed: ${e.response}');
      throw Exception(e.response?.data["message"] ?? "Login failed");
    }
  }

  Future<dynamic> register(
    String email,
    String password,
    String firstName,
    String lastName,
    String phone, {
    String birthday = "2003-01-01",
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          // 'phone': phone,
          'birthday': birthday,
        },
      );
      print('register was successful');
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

  Future<dynamic> signInWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        '/api/auth/Oauth/google',
        data: {'token': idToken},
      );
      print('✅ Google Sign-In successful');
      return response;
    } on DioException catch (e) {
      print('❌ Google Sign-In failed: ${e.response}');
      rethrow;
    }
  }

  Future<dynamic> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/api/auth/forget-password',
        data: {'email': email},
      );
      print('✅ Forgot password successful');
      return response;
    } on DioException catch (e) {
      print('❌ Forgot password failed: ${e.response}');
      rethrow;
    }
  }
}
