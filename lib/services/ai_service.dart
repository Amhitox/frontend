import 'package:dio/dio.dart';
import '../models/ai_response.dart';

class AiService {
  final Dio _dio;

  AiService({required Dio dio}) : _dio = dio;

  Future<AiResponse?> processQuery(String text, String userId, String timezoneOffset, {String? accessToken, Map<String, dynamic>? tokens}) async {
    try {
      final headers = <String, dynamic>{};
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final Map<String, dynamic> body = {
        'text': text,
        'userId': userId,
        'timezoneOffset': timezoneOffset,
      };

      if (tokens != null) {
        body['googleTokens'] = tokens;
      }

      final response = await _dio.post(
        '/api/ai',
        data: body,
        options: Options(headers: headers),
      );
      print('✅ AI Response: ${response.data}');
      return AiResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Error calling AI endpoint: ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Unexpected error in AI Service: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateReply(String originalMessageId, String instructions, String userId, {String? accessToken}) async {
    try {
      final headers = <String, dynamic>{};
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.post(
        '/api/ai/generate-reply',
        data: {
          'originalMessageId': originalMessageId,
          'instructions': instructions,
          'userId': userId, // Ensure userId is passed if required by backend, usually auth token handles user context but explicit userId was in prompt
        },
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      return null;
    } catch (e) {
      return null;
    }
  }
}
