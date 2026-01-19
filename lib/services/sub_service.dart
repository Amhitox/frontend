import 'package:dio/dio.dart';
class SubService {
  final Dio _dio;
  SubService({required Dio dio}) : _dio = dio;
  Future<dynamic> startSubscription(String priceId, {String? paymentMethod}) async {
    try {
      final data = {'price_id': priceId};
      if (paymentMethod != null) {
        data['payment_method'] = paymentMethod;
      }
      
      final response = await _dio.post(
        '/api/subscribe',
        data: data,
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

  Future<dynamic> getSubscription() async {
    try {
      final response = await _dio.get('/api/subscribe');
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<dynamic> cancelSubscription(String subscriptionId) async {
    try {
      final response = await _dio.post(
        '/api/subscribe/cancel',
        data: {'subscription_id': subscriptionId},
      );
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }
}
