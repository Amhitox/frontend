import 'package:dio/dio.dart';
class SubService {
  final Dio _dio;
  SubService({required Dio dio}) : _dio = dio;
  Future<dynamic> startSubscription(String priceId) async {
    try {
      final response = await _dio.post(
        '/api/subscribe',
        data: {'price_id': priceId},
      );
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }
  Future<dynamic> confirmSubscription(
    String subscriptionId,
    String customerId,
  ) async {
    try {
      final response = await _dio.post(
        '/api/subscribe/confirm',
        data: {'subscription_id': subscriptionId, 'customer_id': customerId},
      );
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response> getQuotaStatus({String? timezoneOffset}) async {
    return await _dio.get(
      '/api/users/quota',
      queryParameters: timezoneOffset != null ? {'timezoneOffset': timezoneOffset} : null,
    );
  }

  Future<Response> getPriorityEmails(String userId) async {
    return await _dio.get(
      '/api/settings/priority-emails',
      queryParameters: {'userId': userId},
    );
  }

  Future<Response> addPriorityEmail(String userId, String email) async {
    return await _dio.post(
      '/api/settings/priority-emails',
      data: {'userId': userId, 'email': email},
    );
  }

  Future<Response> removePriorityEmail(String userId, String email) async {
    return await _dio.delete(
      '/api/settings/priority-emails',
      queryParameters: {'userId': userId, 'email': email},
    );
  }
}
