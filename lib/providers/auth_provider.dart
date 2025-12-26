import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/calendar_manager.dart';
import 'package:frontend/managers/task_manager.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
      await TaskManager().init(_user!.id ?? 'default_user');
      await CalendarManager().init(_user!.id ?? 'default_user');
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
      // Get FCM token and device info
      final fcmData = await _getFcmTokenAndDeviceInfo();

      final response = await _authService.loginWithFcm(
        email,
        password,
        fcmData,
      );
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data["user"]);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user', jsonEncode(_user!.toJson()));
        await TaskManager().init(_user!.id ?? 'default_user');
        await CalendarManager().init(_user!.id ?? 'default_user');
        await _cookieJar.loadForRequest(Uri.parse(AppConstants.baseUrl));
        if (response.data["needsEmailVerification"] == true) {
          _errorMessage =
              "Email not verified. Please check your email for verification.";
        }
        return true;
      } else {
        _errorMessage =
            response.data?["message"] ?? "Invalid email or password.";
        return false;
      }
    } on DioException catch (e) {
      _errorMessage =
          e.response?.data?["message"] ?? "Network error. Please try again.";
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
            response.data["message"] ??
            "Account created successfully! check your email for verification";
        return true;
      } else {
        final data = response.data;
        if (data != null) {
           if (data["error"] == "Validation failed" && data["details"] is List) {
             _errorMessage = (data["details"] as List)
                .map((e) => e["message"]?.toString() ?? e.toString())
                .join("\n");
           } else {
             _errorMessage = data["error"] ?? data["message"] ?? "Registration failed. Please try again.";
           }
        } else {
           _errorMessage = "Registration failed. Please try again.";
        }
        return false;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data != null) {
         if (data["error"] == "Validation failed" && data["details"] is List) {
             _errorMessage = (data["details"] as List)
                .map((item) => item["message"]?.toString() ?? item.toString())
                .join("\n");
         } else {
             _errorMessage = data["error"] ?? data["message"] ?? e.message ?? "Network error. Please try again.";
         }
      } else {
         _errorMessage = e.message ?? "Network error. Please try again.";
      }
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
        await CalendarManager().logout();
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
      _isLoading = true;
      notifyListeners();

      // Don't specify clientId - let it use the default from google-services.json
      // This ensures the correct Android client ID is used
      await _googleSignIn.initialize(
        clientId:
            "1025295810293-4sh9femgtgg0rkis92j5s4kq9u04m5vv.apps.googleusercontent.com",
      );

      final account = await _googleSignIn.authenticate();

      final auth = account.authentication;
      if (auth.idToken == null) {
        _errorMessage = "Failed to get authentication token. Please try again.";
        return false;
      }
      final userCreds = GoogleAuthProvider.credential(idToken: auth.idToken);
      await FirebaseAuth.instance.signInWithCredential(userCreds);
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken();

      // Get FCM token and device info
      final fcmData = await _getFcmTokenAndDeviceInfo();

      final googleResponse = await _authService.signInWithGoogle(
        idToken!,
        fcmData,
      );
      if (googleResponse.statusCode == 200) {
        final response = await _authService.getMe();
        _user = User.fromJson(response.data["user"]);
        _errorMessage = "nothing";
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user', jsonEncode(_user!.toJson()));
        await TaskManager().init(_user!.id ?? 'default_user');
        await CalendarManager().init(_user!.id ?? 'default_user');
        notifyListeners();
        await _cookieJar.loadForRequest(Uri.parse(AppConstants.baseUrl));
        return true;
      } else {
        _errorMessage =
            googleResponse.data["message"] ?? "Google Sign-In failed";
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint("Google Sign-In error: $e");
      debugPrint("Stack trace: $stackTrace");

      final errorString = e.toString();

      // Check if user canceled the sign-in
      // The error message says "activity is cancelled by the user" but user claims they didn't cancel
      // This could be due to: back button press, system killing activity, or actual user cancel
      if (errorString.contains('GoogleSignInExceptionCode.canceled') ||
          errorString.contains('canceled')) {
        // Check the actual error message to see if it says "by the user"
        final lowerError = errorString.toLowerCase();
        if (lowerError.contains('activity is cancelled by the user') ||
            lowerError.contains('cancelled by the user') ||
            lowerError.contains('by the user')) {
          // This can happen even if user didn't explicitly cancel
          // Could be: back button, system killing activity, or config issue
          _errorMessage =
              "Sign-in was interrupted. This can happen if the sign-in dialog closes unexpectedly. Please try again.";
        } else {
          // System error or other cancel reason
          _errorMessage = "Sign-in was interrupted. Please try again.";
        }
        return false;
      }

      // Check for specific Google Sign-In exceptions
      if (errorString.contains('GoogleSignInException') ||
          (errorString.contains('GoogleSignIn') &&
              (errorString.contains('Exception') ||
                  errorString.contains('error')))) {
        _errorMessage = "Google Sign-In failed. Please try again.";
      } else if (e is FirebaseAuthException) {
        _errorMessage = e.message ?? "Authentication failed. Please try again.";
      } else if (e is DioException) {
        _errorMessage =
            e.response?.data?["message"] ??
            e.message ??
            "Network error. Please try again.";
      } else {
        // Extract a cleaner error message
        String message = errorString;
        message = message.replaceAll('Exception: ', '');
        message = message.replaceAll('Exception', '');
        message = message.trim();

        // If it's a generic exception, show a more helpful message
        if (message.isEmpty || message == errorString) {
          _errorMessage = "An error occurred during sign-in. Please try again.";
        } else {
          _errorMessage = message;
        }
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<dynamic> signInWithApple() async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken();

      // Get FCM token and device info
      final fcmData = await _getFcmTokenAndDeviceInfo();

      final response = await _authService.signInWithApple(
        idToken!,
        credential.givenName,
        credential.familyName,
        fcmData,
      );

      if (response.statusCode == 200) {
        final authResponse = await _authService.getMe();
        _user = User.fromJson(authResponse.data["user"]);
        _errorMessage = "nothing";
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user', jsonEncode(_user!.toJson()));
        await TaskManager().init(_user!.id ?? 'default_user');
        await CalendarManager().init(_user!.id ?? 'default_user');
        notifyListeners();
        await _cookieJar.loadForRequest(Uri.parse(AppConstants.baseUrl));
        return true;
      } else {
        _errorMessage = response.data["message"] ?? "Apple Sign-In failed";
        return false;
      }
    } catch (e) {
      debugPrint("Apple Sign-In error: $e");
      if (e is SignInWithAppleAuthorizationException) {
         if (e.code == AuthorizationErrorCode.canceled) {
            _errorMessage = "Sign in canceled";
         } else {
            _errorMessage = e.message;
         }
      } else if (e is FirebaseAuthException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = "An error occurred during Apple Sign-In";
      }
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
      _errorMessage =
          e.response?.data?["message"] ??
          "Failed to send password reset email.";
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
      _errorMessage =
          e.response?.data?["message"] ?? "Failed to reset password.";
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Failed to reset password.";
      return false;
    }
  }

  Future<dynamic> verifyEmail(String token) async {
    try {
      await FirebaseAuth.instance.applyActionCode(token);
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?["message"] ?? "Failed to verify email.";
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Failed to verify email.";
      return false;
    }
  }

  Future<void> _saveUserToPrefs() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));
    }
  }

  Future<void> updateUserInSession(User updatedUser) async {
    _user = updatedUser;
    await _saveUserToPrefs();
    notifyListeners();
  }

  Future<void> syncLanguagePreference() async {
    if (_user?.lang != null) {
      // This will be called from the language provider when needed
      // The language provider will handle the actual language setting
    }
  }

  /// Get FCM token and device information for push notifications
  /// Returns a map with fcmToken, deviceId, and deviceType, or null if unavailable
  Future<Map<String, String>?> _getFcmTokenAndDeviceInfo() async {
    try {
      // Get FCM token
      final messaging = FirebaseMessaging.instance;
      String? fcmToken;

      // Request permission for notifications (iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        fcmToken = await messaging.getToken();
      }

      if (fcmToken == null) {
        debugPrint('⚠️ FCM token not available');
        return null;
      }

      // Get device info
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceId;
      String deviceType;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id; // Android ID
        deviceType = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceType = 'ios';
      } else {
        // Web or other platform
        deviceId = 'web-${DateTime.now().millisecondsSinceEpoch}';
        deviceType = 'web';
      }

      return {
        'fcmToken': fcmToken,
        'deviceId': deviceId,
        'deviceType': deviceType,
      };
    } catch (e) {
      debugPrint('⚠️ Error getting FCM token or device info: $e');
      return null;
    }
  }
}
