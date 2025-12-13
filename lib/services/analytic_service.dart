import 'package:dio/dio.dart';

class AnalyticService {
  final Dio _dio;

  AnalyticService({required Dio dio}) : _dio = dio;

  Future<Response> getAnalytics(String period) async {
    
    try {
      final response = await _dio.get(
        '/api/analytic',
        queryParameters: {'period': period},
      );
      return response;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: e.requestOptions,
            statusCode: 500,
            data: {'error': 'Network error'},
          );
    }
  }
  Future<Response> downloadReport(String userId, String filter) async {
    try {
      final response = await _dio.get(
        '/api/analytic/report',
        queryParameters: {'userId': userId, 'filter': filter},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: e.requestOptions,
            statusCode: 500,
            data: {'error': 'Network error'},
          );
    }
  }
}
