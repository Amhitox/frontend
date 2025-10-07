import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class MailService {
  final Dio _dio;
  MailService({required Dio dio}) : _dio = dio;

  Future<dynamic> connect() async {
    try {
      final response = await _dio.get('/api/email/gmail/connect');
      await _launchUrl(response.data['authUrl']);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  Future<dynamic> sendEmail(String email, String subject, String body) async {
    try {
      final response = await _dio.post(
        '/api/email/gmail/send',
        data: {'email': email, 'subject': subject, 'body': body},
      );
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }
}

class DeepLinkService {
  static DeepLinkService? _instance;
  late AppLinks _appLinks;
  StreamSubscription? _sub;

  final Dio _dio;

  // Store pending deep link data
  static Map<String, dynamic>? _pendingCallbackData;

  DeepLinkService._({required Dio dio}) : _dio = dio {
    _appLinks = AppLinks();
  }

  factory DeepLinkService({required Dio dio}) {
    _instance ??= DeepLinkService._(dio: dio);
    return _instance!;
  }

  /// Get and clear pending callback data
  static Map<String, dynamic>? getPendingCallbackData() {
    final data = _pendingCallbackData;
    _pendingCallbackData = null;
    return data;
  }

  /// Initialize deep link listening
  Future<void> initDeepLinks({
    required Function(bool success, String? error, String? email)
    onGmailConnected,
  }) async {
    print('🔗 Initializing deep link service...');

    // Handle initial link if app was closed
    await _handleInitialLink(onGmailConnected);

    // Handle links while app is active
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri, onGmailConnected);
      },
      onError: (err) {
        print('❌ Deep link error: $err');
        _storePendingData(false, 'Deep link error: $err', null);
        onGmailConnected(false, 'Deep link error: $err', null);
      },
    );

    print('✅ Deep link service initialized successfully');
  }

  /// Handle initial link when app starts
  Future<void> _handleInitialLink(
    Function(bool success, String? error, String? email) onGmailConnected,
  ) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('🔗 Initial deep link detected: $initialUri');
        _handleDeepLink(initialUri, onGmailConnected);
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }
  }

  /// Store callback data for later retrieval
  void _storePendingData(bool success, String? error, String? email) {
    _pendingCallbackData = {
      'success': success,
      'error': error,
      'email': email,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    print('📦 Stored pending callback data: $_pendingCallbackData');
  }

  /// Process the deep link - ONLY handles backend callback format
  void _handleDeepLink(
    Uri uri,
    Function(bool success, String? error, String? email) onGmailConnected,
  ) {
    print('🔗 Received deep link: $uri');

    // Only handle the backend Gmail callback format
    if (uri.scheme == 'aixy' &&
        uri.host == 'gmail' &&
        uri.path == '/callback') {
      final success = uri.queryParameters['success'] == 'true';
      final error = uri.queryParameters['error'];
      final email = uri.queryParameters['email'];

      print('📧 Backend Gmail callback detected');

      if (success && email != null) {
        print('✅ Gmail connected: $email');
        _storePendingData(true, null, email);
        onGmailConnected(true, null, email);
      } else {
        final errorMsg = error ?? 'Gmail connection failed';
        print('❌ Backend error: $errorMsg');
        _storePendingData(false, errorMsg, null);
        onGmailConnected(false, errorMsg, null);
      }
    } else {
      print('⚠️ Unhandled deep link format: $uri');
    }
  }

  static void clearPendingCallbackData() {
    _pendingCallbackData = null;
    print('🗑️ Cleared pending callback data');
  }

  /// Dispose the stream subscription
  void dispose() {
    _sub?.cancel();
  }
}
