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
      return e.response;
    }
  }

  Future<dynamic> register(
    String email,
    String password,
    String firstName,
    String lastName, {
    String phone = "+212622107249",
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
          'phone': phone,
          'birthday': birthday,
        },
      );
      print('register was successful');
      return response;
    } on DioException catch (e) {
      print('❌ Register failed: ${e.message}');
      return e.response;
    }
  }

  Future<dynamic> logout() async {
    try {
      final response = await _dio.post('/api/auth/logout');
      print('Logout successfully');
      return response;
    } on DioException catch (e) {
      print('Logout failed');
      return e.response;
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
      return e.response;
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
      return e.response;
    }
  }

  Future<dynamic> getMe() async {
    try {
      final response = await _dio.get('/api/auth/me');
      print('✅ Get me successful');
      return response;
    } on DioException catch (e) {
      print('❌ Get me failed: ${e.response}');
      return e.response;
    }
  }
}
