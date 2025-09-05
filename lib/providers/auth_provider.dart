import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  late AuthService _authService;
  late PersistCookieJar _cookieJar;
  late Dio _dio;
  bool _isLoading = false;
  User? _user;
  String? _errorMessage;

  Dio get dio => _dio;
  bool get isLoading => _isLoading;
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/cookies/'));
    _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    _dio.interceptors.add(CookieManager(_cookieJar));
    _authService = AuthService(dio: _dio);

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
      notifyListeners();
    }

    final cookies = await _cookieJar.loadForRequest(
      Uri.parse(AppConstants.baseUrl),
    );
    if (cookies.isNotEmpty) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }

    print("Cookies loaded from storage: $cookies");
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);

      if (response.statusCode == 200) {
        _user = User.fromJson(response.data["user"]);
        _errorMessage = null;
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user', jsonEncode(_user!.toJson()));
        notifyListeners();
        final cookies = await _cookieJar.loadForRequest(
          Uri.parse(AppConstants.baseUrl),
        );
        print("Cookies after login: $cookies");
        return true;
      } else {
        _errorMessage = response.data["message"] ?? "Login failed";
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<dynamic> logout() async {
    try {
      if (_user != null) {
        final response = await _authService.logout();
        _user = null;
        await _cookieJar.deleteAll();
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('user');
        notifyListeners();
        return response.statusCode == 200;
      }
    } catch (e, stacktrace) {
      debugPrint("Logout error: $e");
      debugPrintStack(stackTrace: stacktrace);
    }
  }

  Future<dynamic> signInWithGoogle() async {}
}
