import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/utils/error_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  late AuthService _authService;
  late PersistCookieJar _cookieJar;
  late Dio _dio;
  bool _isLoading = false;
  User? _user;
  String? _errorMessage;
  final _googleSignIn = GoogleSignIn.instance;
  final firebaseAuth = FirebaseAuth.instance;

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
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _authService.login(email, password);

      if (response.statusCode == 200) {
        _user = User.fromJson(response.data["user"]);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user', jsonEncode(_user!.toJson()));
        await _cookieJar.loadForRequest(Uri.parse(AppConstants.baseUrl));
        _errorMessage = handleErrorResponse(response);
        return true;
      } else {
        _errorMessage = handleErrorResponse(response);
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = handleErrorResponse(e.response);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _authService.register(
        email,
        password,
        firstName,
        lastName,
        phone: phone,
        birthday: birthday,
      );
      if (response.statusCode == 201) {
        _errorMessage =
            "Account created successfully! check your email for verification";
        return true;
      } else {
        _errorMessage = handleErrorResponse(response);
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = handleErrorResponse(e);
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
        FirebaseAuth.instance.signOut();
        _googleSignIn.signOut();
        notifyListeners();
        return response.statusCode == 200;
      }
    } catch (e, stacktrace) {
      debugPrint("Logout error: $e");
      debugPrintStack(stackTrace: stacktrace);
    }
  }

  Future<dynamic> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        clientId:
            "1025295810293-u860lppt8rbo4u0aqtnsbms70dp3oci7.apps.googleusercontent.com",
      );
      final account = await _googleSignIn.authenticate();
      _isLoading = true;
      notifyListeners();

      final auth = account.authentication;

      if (auth.idToken == null) {
        throw Exception("Google Sign-In failed");
      }

      final userCreds = GoogleAuthProvider.credential(idToken: auth.idToken);

      await FirebaseAuth.instance.signInWithCredential(userCreds);

      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken();

      final googleResponse = await _authService.signInWithGoogle(idToken!);

      if (googleResponse.statusCode == 200) {
        final response = await _authService.getMe();
        _user = User.fromJson(response.data["user"]);
        _errorMessage = "nothing";
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user', jsonEncode(_user!.toJson()));
        notifyListeners();
        await _cookieJar.loadForRequest(Uri.parse(AppConstants.baseUrl));
        print(response);
        print(_user);
        return true;
      } else {
        _errorMessage =
            googleResponse.data["message"] ?? "Google Sign-In failed";
        return false;
      }
    } catch (e) {
      _errorMessage = handleErrorResponse(e);
      print('❌ Google Sign-In failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<dynamic> forgotPassword(String email) async {
    try {
      final response = await _authService.forgotPassword(email);
      return response;
    } on DioException catch (e) {
      print('❌ Forgot password failed: ${e.response}');
      _errorMessage = handleErrorResponse(e.response);
      return false;
    }
  }

  Future<dynamic> resetPassword(String code, String newPassword) async {
    try {
      await firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      return true;
    } on DioException catch (e) {
      print('❌ Reset password failed: ${e.response}');
      _errorMessage = handleErrorResponse(e.response);
      return false;
    }
  }

  Future<dynamic> verifyEmail(String token) async {
    try {
      await FirebaseAuth.instance.applyActionCode(token);
      return true;
    } on DioException catch (e) {
      print('❌ Verify email failed: ${e.response}');
      _errorMessage = handleErrorResponse(e.response);
      return false;
    }
  }
}
