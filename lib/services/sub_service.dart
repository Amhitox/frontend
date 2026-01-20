import 'package:dio/dio.dart';
class SubService {
  final Dio _dio;
  SubService({required Dio dio}) : _dio = dio;


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


  Future<Response> signCmiPayment({
    required double amount,
    required Map<String, dynamic> userInfo,
    String? transactionId,
  }) async {
    return await _dio.post(
      '/api/payment/cmi/sign',
      data: {
        'amount': amount,
        'userInfo': userInfo,
        if (transactionId != null) 'transactionId': transactionId,
      },
    );
  }
}
