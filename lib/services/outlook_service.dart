import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class OutlookService {
  final Dio _dio;
  String? _accessToken;

  OutlookService({required Dio dio}) : _dio = dio;

  // --- Authentication ---

  Future<dynamic> connect() async {
    try {
      final response = await _dio.get(
        '/api/email/outlook/connect',
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
      print('❌ Outlook Connect error: ${e.response?.data}');
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
      final response = await _dio.get('/api/email/outlook/check-tokens');
      print('✅ Outlook Token check response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error checking Outlook tokens');
      return null;
    }
  }

  Future<bool> disconnect() async {
    try {
      await _dio.post('/api/email/outlook/disconnect');
      clearLocalData();
      print('✅ Outlook disconnected');
      return true;
    } on DioException catch (e) {
      print('❌ Error disconnecting Outlook: ${e.message}');
      return false;
    }
  }

  void clearLocalData() {
    _accessToken = null;
  }

  Future<bool> initialize() async {
     try {
      final tokenData = await checkTokens();
      if (tokenData != null && tokenData['hasTokens'] == true) {
        // Outlook API on backend might verify session token, 
        // but if we need access token on client side, we'd get it here.
        // Assuming backend handles token management mostly via session/cookies or 
        // we might store it if returned.
        // Based on Gmail implementation, we might store accessToken if returned via checkTokens.
        if (tokenData['tokens'] != null && tokenData['tokens']['accessToken'] != null) {
             _accessToken = tokenData['tokens']['accessToken'];
        }
        print('✅ Outlook service initialized');
        return true;
      }
      print('⚠️ No Outlook tokens found');
      return false;
    } catch (e) {
      print('❌ Failed to initialize Outlook service: $e');
      return false;
    }
  }


  // --- User & Metadata ---

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _dio.get('/api/email/outlook/user');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error fetching Outlook user profile: ${e.message}');
      return null;
    }
  }

  // --- Email Operations ---

  Future<Map<String, dynamic>?> listMails({
    String type = 'inbox',
    int maxResults = 20,
    String? pageToken,
    String? query,
  }) async {
    try {
      final response = await _dio.get(
        '/api/email/outlook/list',
        queryParameters: {
          'type': type,
          'maxResults': maxResults,
          if (pageToken != null) 'pageToken': pageToken,
          if (query != null) 'q': query,
        },
      );
      return response.data;
    } on DioException catch (e) {
      print('❌ Error listing Outlook mails: ${e.response?.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEmailDetails(String messageId) async {
    try {
      final response = await _dio.get('/api/email/outlook/$messageId');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error fetching Outlook email details: ${e.message}');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getFullContent(String messageId) async {
     try {
      final response = await _dio.post('/api/email/outlook/get-full-content', data: {'messageId': messageId});
      return response.data;
    } on DioException catch (e) {
      print('❌ Error fetching Outlook full content: ${e.message}');
      return null;
    }
  }


  Future<bool> markAsRead(String messageId) async {
    try {
      final response = await _dio.post(
        '/api/email/outlook/mark-read',
        data: {'messageId': messageId},
      );
      return response.statusCode == 200 || (response.data['success'] == true);
    } on DioException catch (e) {
      print('❌ Error marking Outlook email as read: ${e.message}');
      return false;
    }
  }
  
  // Outlook API doesn't seem to have explicit unread endpoint listed in user prompt,
  // but usually it's supported. If not, we skip or assume similar to read.
  // User prompt said: POST /api/email/outlook/mark-read. 
  // Doesn't mention mark-unread. Will assume not supported or verified later.

  Future<bool> deleteEmail(String messageId) async {
    try {
      final response = await _dio.delete('/api/email/outlook/$messageId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error deleting Outlook email: ${e.message}');
      return false;
    }
  }

  Future<Map<String, dynamic>?> summarizeEmail(String messageId) async {
    try {
      final response = await _dio.post(
        '/api/email/outlook/summarize',
        data: {'messageId': messageId},
      );
      return response.data;
    } on DioException catch (e) {
      print('❌ Error summarizing Outlook email: ${e.message}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    List<File>? attachments,
    List<Map<String, dynamic>>? byteAttachments,
  }) async {
    try {
       final formDataMap = <String, dynamic>{
        'to': to,
        'subject': subject,
        'body': body,
      };
      
      if (cc != null) formDataMap['cc'] = cc;
      if (bcc != null) formDataMap['bcc'] = bcc;

      final formData = FormData.fromMap(formDataMap);

      if (attachments != null) {
        for (var file in attachments) {
           if (await file.exists()) {
             final filename = file.path.split('/').last;
             formData.files.add(MapEntry(
               'attachments',
               await MultipartFile.fromFile(file.path, filename: filename),
             ));
           }
        }
      }
      
      if (byteAttachments != null) {
        for (var att in byteAttachments) {
           final name = att['name'];
           final bytes = att['bytes'] as List<int>?;
           final path = att['path'] as String?;
           if (bytes != null) {
             formData.files.add(MapEntry('attachments', MultipartFile.fromBytes(bytes, filename: name)));
           } else if (path != null) {
              formData.files.add(MapEntry('attachments', await MultipartFile.fromFile(path, filename: name)));
           }
        }
      }

      final response = await _dio.post('/api/email/outlook/send', data: formData);
      return response.data;

    } on DioException catch (e) {
      print('❌ Error sending Outlook email: ${e.response?.data}');
      return e.response?.data;
    }
  }

  // --- Drafts ---

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

      final response = await _dio.post(
        '/api/email/outlook/draft', 
        data: formData,
      );

      return response.data;
      
    } on DioException catch (e) {
      print('❌ Error creating Outlook draft: ${e.response?.data}');
      return e.response?.data ?? {'error': e.message};
    }
  }

  // --- Other Actions ---

  Future<bool> markAsUnread(String messageId) async {
    try {
      final response = await _dio.patch(
        '/api/email/outlook/$messageId/unread',
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Error marking Outlook email as unread: ${e.message}');
      return false;
    }
  }

  Future<void> downloadAttachment(
    String messageId,
    String attachmentId,
    String filename,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';

      await _dio.download(
        '/api/email/outlook/$messageId/attachments/$attachmentId',
        filePath,
      );

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      print('❌ Error downloading Outlook attachment: $e');
      rethrow;
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
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return {'error': response.data['message'] ?? 'Refinement failed'};
    } on DioException catch (e) {
      return {'error': e.response?.data['error'] ?? e.message};
    }
  }
}
