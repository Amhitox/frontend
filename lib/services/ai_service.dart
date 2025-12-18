import 'package:dio/dio.dart';
import '../models/ai_response.dart';

class AiService {
  final Dio _dio;

  AiService({required Dio dio}) : _dio = dio;

  Future<AiResponse?> processQuery(String text, String userId, String timezoneOffset) async {
    try {
      final response = await _dio.post(
        '/api/ai',
        data: {
          'text': text,
          'userId': userId,
          'timezoneOffset': timezoneOffset,
        },
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
}
