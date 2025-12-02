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
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<dynamic> loginWithFcm(
    String email,
    String password,
    Map<String, String>? fcmData,
  ) async {
    try {
      final data = {
        'email': email,
        'password': password,
        if (fcmData != null) ...fcmData,
      };
      final response = await _dio.post(
        '/api/auth/login',
        data: data,
      );
      return response;
    } on DioException catch (e) {
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
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<dynamic> logout() async {
    try {
      final response = await _dio.post('/api/auth/logout');
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<dynamic> signInWithGoogle(
    String idToken,
    Map<String, String>? fcmData,
  ) async {
    try {
      final data = {
        'token': idToken,
        if (fcmData != null) ...fcmData,
      };
      final response = await _dio.post(
        '/api/auth/Oauth/google',
        data: data,
      );
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<dynamic> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/api/auth/forget-password',
        data: {'email': email},
      );
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<dynamic> getMe() async {
    try {
      final response = await _dio.get('/api/auth/me');
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }
}
