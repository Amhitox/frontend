import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/sub_service.dart';

class SubProvider extends ChangeNotifier {
  final SubService subService;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SubProvider({required Dio dio}) : subService = SubService(dio: dio);

  Future<dynamic> startSubscription(String priceId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await subService.startSubscription(priceId);
      print(response);
      return response;
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.response;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<dynamic> confirmSubscription(
    String subscriptionId,
    String customerId,
  ) async {
    _isLoading = true;
    notifyListeners();
    final response = await subService.confirmSubscription(
      subscriptionId,
      customerId,
    );
    return response;
  }
}
