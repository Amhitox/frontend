import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/email_message.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class MailService {
  final Dio _dio;
  String? _accessToken;

  MailService({required Dio dio}) : _dio = dio;

  String? get accessToken => _accessToken;

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
    String? query,
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
          if (query != null && query.isNotEmpty) 'q': query,
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
        final errorData = e.response?.data;
        if (errorData is Map &&
            errorData['error'] == 'Refresh token not found') {
          return {'error': 'Refresh token not found'};
        }
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
                if (query != null && query.isNotEmpty) 'q': query,
              },
              options: Options(
                headers: {'Authorization': 'Bearer $_accessToken'},
              ),
            );
            return retryResponse.data;
          } catch (retryError) {
            print('❌ Retry failed: $retryError');
            return {'error': 'Failed to fetch emails'};
          }
        }
      }

      if (e.response?.statusCode == 500) {
        return {'error': 'Failed to fetch emails'};
      }

      return {'error': e.response?.data?['error'] ?? 'Failed to fetch emails'};
    }
  }

  Future<Map<String, dynamic>?> sendEmail(
    String to,
    String subject,
    String body,
    List<File>? attachments,
  ) async {
    if (_accessToken == null) {
      await initialize();
    }

    try {
      final formData = FormData.fromMap({
        'to': to,
        'subject': subject,
        'body': body,
      });

      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          if (await file.exists()) {
            final filename = file.path.split('/').last;
            formData.files.add(
              MapEntry(
                'attachments',
                await MultipartFile.fromFile(file.path, filename: filename),
              ),
            );
          }
        }
      }

      final response = await _dio.post('/api/send', data: formData);

      print('✅ Email sent successfully');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error sending email: ${e.response?.data}');
      return e.response?.data;
    }
  }

  // Helper method to send email with bytes attachments (for file_picker)
  // Backend expects FormData with: to, subject, body, and attachments (as Files)
  // Backend uses cookie-based authentication via authenticateRequest(req)
  Future<Map<String, dynamic>?> sendEmailWithBytes(
    String to,
    String subject,
    String body,
    List<Map<String, dynamic>>? attachments, {
    String? cc,
    String? bcc,
  }) async {
    try {
      final formDataMap = {'to': to, 'subject': subject, 'body': body};

      if (cc != null && cc.isNotEmpty) {
        formDataMap['cc'] = cc;
      }
      if (bcc != null && bcc.isNotEmpty) {
        formDataMap['bcc'] = bcc;
      }

      final formData = FormData.fromMap(formDataMap);

      if (attachments != null && attachments.isNotEmpty) {
        for (var attachment in attachments) {
          final name = attachment['name'] as String;
          final bytes = attachment['bytes'] as List<int>?;
          final path = attachment['path'] as String?;

          if (bytes != null && bytes.isNotEmpty) {
            formData.files.add(
              MapEntry(
                'attachments',
                MultipartFile.fromBytes(bytes, filename: name),
              ),
            );
          } else if (path != null && path.isNotEmpty) {
            formData.files.add(
              MapEntry(
                'attachments',
                await MultipartFile.fromFile(path, filename: name),
              ),
            );
          }
        }
      }

      final options = Options(
        headers:
            _accessToken != null
                ? {'Authorization': 'Bearer $_accessToken'}
                : null,
      );

      final response = await _dio.post(
        '/api/email/gmail/send',
        data: formData,
        options: options,
      );

      final responseData = response.data;

      if (response.statusCode == 200 && responseData['success'] == true) {
        print(
          '✅ Email sent successfully. MessageId: ${responseData['messageId']}',
        );
        return responseData;
      } else {
        print(
          '⚠️ Email send failed with status ${response.statusCode}: $responseData',
        );
        return responseData is Map<String, dynamic>
            ? responseData
            : {'error': responseData.toString()};
      }
    } on DioException catch (e) {
      print('❌ Error sending email: ${e.response?.data}');
      final errorData = e.response?.data;
      final statusCode = e.response?.statusCode;

      if (statusCode == 400) {
        if (errorData is Map) {
          return {'error': errorData['error'] ?? 'Missing required fields'};
        }
        return {'error': 'Gmail not connected or missing required fields'};
      }

      if (statusCode == 401) {
        if (errorData is Map) {
          return {
            'error': errorData['error'] ?? 'Failed to refresh Gmail tokens',
            'details': errorData['details'],
          };
        }
        return {'error': 'Failed to refresh Gmail tokens'};
      }

      if (statusCode == 500) {
        if (errorData is Map) {
          return {
            'error': 'Failed to send email',
            'details': errorData['details'],
          };
        }
        return {'error': 'Failed to send email'};
      }

      if (errorData is Map<String, dynamic>) {
        return errorData;
      }
      return {'error': errorData?.toString() ?? e.message ?? 'Unknown error'};
    }
  }

  // Same structure as sendEmailWithBytes but hits the draft endpoint
  Future<Map<String, dynamic>?> createDraft(
    String to,
    String subject,
    String body,
    List<Map<String, dynamic>>? attachments, {
    String? cc,
    String? bcc,
  }) async {
    try {
      final formDataMap = <String, dynamic>{};

      if (to.isNotEmpty) formDataMap['to'] = to;
      if (subject.isNotEmpty) formDataMap['subject'] = subject;
      if (body.isNotEmpty) formDataMap['body'] = body;

      if (cc != null && cc.isNotEmpty) {
        formDataMap['cc'] = cc;
      }
      if (bcc != null && bcc.isNotEmpty) {
        formDataMap['bcc'] = bcc;
      }

      final formData = FormData.fromMap(formDataMap);

      if (attachments != null && attachments.isNotEmpty) {
        for (var attachment in attachments) {
          final name = attachment['name'] as String;
          final bytes = attachment['bytes'] as List<int>?;
          final path = attachment['path'] as String?;

          if (bytes != null && bytes.isNotEmpty) {
            formData.files.add(
              MapEntry(
                'attachments',
                MultipartFile.fromBytes(bytes, filename: name),
              ),
            );
          } else if (path != null && path.isNotEmpty) {
            formData.files.add(
              MapEntry(
                'attachments',
                await MultipartFile.fromFile(path, filename: name),
              ),
            );
          }
        }
      }

      final options = Options(
        headers:
            _accessToken != null
                ? {'Authorization': 'Bearer $_accessToken'}
                : null,
      );

      final response = await _dio.post(
        '/api/email/gmail/draft',
        data: formData,
        options: options,
      );

      // Backend returns: { success: true, draftId: "...", message: "..." }
      return response.data;
    } on DioException catch (e) {
      print('❌ Error creating draft: ${e.response?.data}');
      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        return errorData;
      }
      return {'error': errorData?.toString() ?? e.message ?? 'Unknown error'};
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
      clearLocalData();
      print('✅ Gmail disconnected');
      return true;
    } on DioException catch (e) {
      print('❌ Error disconnecting: ${e.message}');
      return false;
    }
  }

  void clearLocalData() {
    _accessToken = null;
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
    try {
      if (_accessToken == null) {
        print('⚠️ No access token, attempting to initialize...');
        final initialized = await initialize();
        if (!initialized) {
          print('❌ Failed to get access token');
          return {'error': 'No access token available'};
        }
      }
      final response = await _dio.get(
        '/api/email/gmail/$messageId',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      print('✅ Email details fetched for: $messageId');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print(
          '⚠️ Email details endpoint not found (404). Using data from list.',
        );
        return null;
      }
      print(
        '❌ Error fetching email details: ${e.response?.statusCode} - ${e.response?.data}',
      );
      return null;
    }
  }

  Future<bool> markAsRead(String messageId) async {
    try {
      final response = await _dio.post(
        '/api/email/gmail/mark-read',
        data: {'messageId': messageId},
      );

      // Backend returns: { success: true, message: "..." }
      final responseData = response.data;
      final success =
          responseData['success'] == true || response.statusCode == 200;

      if (success) {
        print('✅ Email marked as read: $messageId');
      } else {
        print('⚠️ Mark as read returned success: false $messageId');
      }

      return success;
    } on DioException catch (e) {
      print('❌ Error marking email as read: $messageId ${e.response?.data}');
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

  Future<void> watchGmail() async {
    try {
      // 1. Get tokens and email from backend
      final tokenData = await checkTokens();

      if (tokenData != null && tokenData['hasTokens'] == true) {
        final tokens = tokenData['tokens'];
        final accessToken = tokens?['accessToken'];
        final refreshToken = tokens?['refreshToken'];
        final email =
            tokenData['email']; // Assuming 'email' or 'connectedEmail' is top-level or in tokens

        // Note: data structure depends on checkTokens response.
        // Based on typical auth flows, we check if we have what we need.
        // User request specifically asked to send: accessToken, refreshToken, connectedEmail.

        if (accessToken != null) {
          String? connectedEmail = email;

          // If email is missing from checkTokens, try to fetch it from Gmail Profile
          if (connectedEmail == null) {
            try {
              final profileResponse = await _dio.get(
                'https://gmail.googleapis.com/gmail/v1/users/me/profile',
                options: Options(
                  headers: {'Authorization': 'Bearer $accessToken'},
                ),
              );
              if (profileResponse.statusCode == 200) {
                connectedEmail = profileResponse.data['emailAddress'];
                print(
                  '✅ Fetched connected email from profile: $connectedEmail',
                );
              }
            } catch (e) {
              print('⚠️ Failed to fetch Gmail profile: $e');
            }
          }

          if (connectedEmail != null) {
            final body = {
              'accessToken': accessToken,
              'refreshToken': refreshToken ?? '',
              'connectedEmail': connectedEmail,
            };

            print('🔄 Renewing Gmail watch for $connectedEmail...');

            await _dio.post('/api/email/gmail/watch', data: body);
            print('✅ Gmail watch renewed successfully');
          } else {
            print('⚠️ Could not determine connected email for watch renewal');
          }
        } else {
          print('⚠️ Missing access token to renew watch');
        }
      } else {
        print('ℹ️ No Gmail tokens found, skipping watch renewal');
      }
    } catch (e) {
      print('❌ Error renewing Gmail watch: $e');
    }
  }

  Stream<List<EmailMessage>> streamEmails() {
    try {
      return FirebaseFirestore.instance
          .collection('email_summaries')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return EmailMessage.fromFirestore(doc.data(), doc.id);
            }).toList();
          });
    } catch (e) {
      print('❌ Error streaming emails: $e');
      return Stream.value([]);
    }
  }

  Future<Map<String, dynamic>?> refineEmail(
    String currentSubject,
    String currentBody,
    String instruction,
  ) async {
    try {
      final response = await _dio.post(
        '/api/ai/refine-email',
        data: {
          'currentSubject': currentSubject,
          'currentBody': currentBody,
          'instruction': instruction,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      return {'error': response.data['message'] ?? 'Refinement failed'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        return {
          'error': 'Refinement failed',
          'details': e.response?.data?['details'],
        };
      }
      return {
        'error':
            e.response?.data['error'] ??
            e.response?.data['message'] ??
            e.message,
      };
    }
  }

  Future<void> downloadAttachment(
    String messageId,
    String attachmentId,
    String filename,
  ) async {
    if (_accessToken == null) {
      await initialize();
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';

      await _dio.download(
        '/api/email/gmail/$messageId/attachments/$attachmentId',
        filePath,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      print('❌ Error downloading attachment: $e');
      rethrow;
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
    Function(Uri uri)? onMailtoLink,
  }) async {
    print('🔗 Initializing deep link service...');

    await _handleInitialLink(onGmailConnected, onMailtoLink);

    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri, onGmailConnected, onMailtoLink);
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
    Function(Uri uri)? onMailtoLink,
  ) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('🔗 Initial deep link detected: $initialUri');
        _handleDeepLink(initialUri, onGmailConnected, onMailtoLink);
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
    Function(Uri uri)? onMailtoLink,
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
    } else if (uri.host == 'elyoai-999.firebaseapp.com' &&
        uri.path.startsWith('/__/auth/action')) {
      print('🔐 Firebase auth action link detected');
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];

      if (mode != null && oobCode != null) {
        final authUri = Uri(
          path: '/__/auth/action',
          queryParameters: {'mode': mode, 'oobCode': oobCode},
        );

        Future.delayed(const Duration(milliseconds: 100), () {
          final navContext = AppRoutes.navigatorKey.currentContext;
          if (navContext != null) {
            GoRouter.of(navContext).go(authUri.toString());
          }
        });
      }
    } else if (uri.scheme == 'aixy' && uri.host == 'payment') {
      // Handle payment deep link - redirect to subscription screen
      print('💳 Payment deep link detected: $uri');
      Future.delayed(const Duration(milliseconds: 100), () {
        final navContext = AppRoutes.navigatorKey.currentContext;
        if (navContext != null) {
          // Navigate to subscription screen with payment interference flag
          GoRouter.of(
            navContext,
          ).go('/subscription', extra: {'paymentInterfered': true});
        }
      });
    } else if (uri.scheme == 'mailto') {
      print('📧 Mailto link detected: $uri');
      if (onMailtoLink != null) {
        onMailtoLink(uri);
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
