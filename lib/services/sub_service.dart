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
      print('✅ Start subscription successful');
      return response;
    } on DioException catch (e) {
      print('❌ Start subscription failed: ${e.response}');
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
      print('✅ Confirm subscription successful');
      return response;
    } on DioException catch (e) {
      print('❌ Confirm subscription failed: ${e.response}');
      return e.response;
    }
  }
}
