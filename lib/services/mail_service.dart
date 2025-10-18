import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class MailService {
  final Dio _dio;
  String? _accessToken;

  MailService({required Dio dio}) : _dio = dio;

  Future<bool> initialize() async {
    try {
      final tokenData = await checkTokens();
      if (tokenData != null && tokenData['hasTokens'] == true) {
        _accessToken = tokenData['tokens']?['accessToken'];
        print('✅ Mail service initialized with access token');
        return true;
      }
      print('⚠️ No email tokens found');
      return false;
    } catch (e) {
      print('❌ Failed to initialize mail service: $e');
      return false;
    }
  }

  Future<dynamic> connect() async {
    try {
      final response = await _dio.get(
        '/api/email/gmail/connect',
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.data != null && response.data['authUrl'] != null) {
        await _launchUrl(response.data['authUrl']);
        return response.data;
      }

      return {'error': 'No auth URL received'};
    } on DioException catch (e) {
      print('❌ Connect error: ${e.response?.data}');
      return e.response?.data ?? {'error': e.message};
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  Future<Map<String, dynamic>?> checkTokens() async {
    try {
      final response = await _dio.get('/api/email/gmail/check-tokens');
      print('✅ Token check response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error checking tokens');
      print('Status: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> listMails({
    String type = 'inbox',
    int maxResults = 20,
    String? pageToken,
  }) async {
    if (_accessToken == null) {
      print('⚠️ No access token, attempting to initialize...');
      final initialized = await initialize();
      if (!initialized) {
        print('❌ Failed to get access token');
        return {'error': 'No access token available'};
      }
    }

    try {
      final response = await _dio.get(
        '/api/email/gmail/list',
        queryParameters: {
          'type': type,
          'maxResults': maxResults,
          if (pageToken != null) 'pageToken': pageToken,
        },
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      print('✅ Listed ${response.data['messages']?.length ?? 0} emails');
      print(response.data);
      return response.data;
    } on DioException catch (e) {
      print('❌ Error listing mails');
      print('Status: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
      print('Message: ${e.message}');

      if (e.response?.statusCode == 401) {
        print('⚠️ Token expired, attempting to refresh...');
        final refreshed = await initialize();

        if (refreshed && _accessToken != null) {
          print('✅ Token refreshed, retrying request...');
          try {
            final retryResponse = await _dio.get(
              '/api/email/gmail/list',
              queryParameters: {
                'type': type,
                'maxResults': maxResults,
                if (pageToken != null) 'pageToken': pageToken,
              },
              options: Options(
                headers: {'Authorization': 'Bearer $_accessToken'},
              ),
            );
            return retryResponse.data;
          } catch (retryError) {
            print('❌ Retry failed: $retryError');
            return null;
          }
        }
      }

      return null;
    }
  }

  Future<Map<String, dynamic>?> sendEmail(
    String to,
    String subject,
    String body,
  ) async {
    if (_accessToken == null) {
      await initialize();
    }

    try {
      final response = await _dio.post(
        '/api/email/gmail/send',
        data: {'to': to, 'subject': subject, 'body': body},
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      print('✅ Email sent successfully');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error sending email: ${e.response?.data}');
      return e.response?.data;
    }
  }

  Future<Map<String, dynamic>?> summarizeEmail(String messageId) async {
    if (_accessToken == null) {
      await initialize();
    }

    try {
      final response = await _dio.post(
        '/api/email/gmail/summarize',
        data: {'messageId': messageId},
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      print('✅ Email summarized successfully');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error summarizing email: ${e.response?.data}');
      return null;
    }
  }

  Future<bool> deleteEmail(String messageId) async {
    if (_accessToken == null) {
      await initialize();
    }

    try {
      final response = await _dio.delete(
        '/api/email/gmail/$messageId',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      print('✅ Email deleted successfully');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error deleting email: ${e.response?.data}');
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      await _dio.post('/api/email/gmail/disconnect');
      _accessToken = null;
      print('✅ Gmail disconnected');
      return true;
    } on DioException catch (e) {
      print('❌ Error disconnecting: ${e.message}');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/auth/me');
      print('✅ Current user: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Not authenticated: ${e.message}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEmailDetails(String messageId) async {
    if (_accessToken == null) {
      await initialize();
    }

    try {
      final response = await _dio.get(
        '/api/email/gmail/message/$messageId',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      print('✅ Email details fetched for: $messageId');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error fetching email details: ${e.response?.data}');
      return null;
    }
  }

  Future<bool> markAsRead(String messageId) async {
    if (_accessToken == null) {
      await initialize();
    }

    try {
      final response = await _dio.patch(
        '/api/email/gmail/$messageId/read',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      print('✅ Email marked as read: $messageId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error marking email as read: ${e.response?.data}');
      return false;
    }
  }

  Future<bool> markAsUnread(String messageId) async {
    if (_accessToken == null) {
      await initialize();
    }

    try {
      final response = await _dio.patch(
        '/api/email/gmail/$messageId/unread',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      print('✅ Email marked as unread: $messageId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error marking email as unread: ${e.response?.data}');
      return false;
    }
  }
}

class DeepLinkService {
  static DeepLinkService? _instance;
  late AppLinks _appLinks;
  StreamSubscription? _sub;

  static Map<String, dynamic>? _pendingCallbackData;

  DeepLinkService._() {
    _appLinks = AppLinks();
  }

  factory DeepLinkService() {
    _instance ??= DeepLinkService._();
    return _instance!;
  }

  static Map<String, dynamic>? getPendingCallbackData() {
    final data = _pendingCallbackData;
    _pendingCallbackData = null;
    return data;
  }

  Future<void> initDeepLinks({
    required Function(bool success, String? error, String? email)
    onGmailConnected,
  }) async {
    print('🔗 Initializing deep link service...');

    await _handleInitialLink(onGmailConnected);

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

  void _storePendingData(bool success, String? error, String? email) {
    _pendingCallbackData = {
      'success': success,
      'error': error,
      'email': email,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    print('📦 Stored pending callback data: $_pendingCallbackData');
  }

  void _handleDeepLink(
    Uri uri,
    Function(bool success, String? error, String? email) onGmailConnected,
  ) {
    print('🔗 Received deep link: $uri');

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

  void dispose() {
    _sub?.cancel();
  }
}
