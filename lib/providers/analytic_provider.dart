import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/analytic_data.dart';
import 'package:frontend/services/analytic_service.dart';

class AnalyticProvider extends ChangeNotifier {
  final AnalyticService _analyticService;
  
  AnalyticProvider({required Dio dio}) : _analyticService = AnalyticService(dio: dio);

  bool _isLoading = false;
  String? _error;
  final Map<String, AnalyticData> _cache = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AnalyticData? getData(String period) => _cache[period];

  Future<void> fetchAnalytics(String period, {bool forceRefresh = false}) async {
    if (_cache.containsKey(period) && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _analyticService.getAnalytics(period);
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
             _cache[period] = AnalyticData.fromJson(data['data']);
             notifyListeners(); 
        } else {
             _error = "Failed to load data: ${data['message'] ?? 'Unknown error'}";
        }
      } else {
        _error = "Server error: ${response.statusCode}";
      }
    } catch (e) {
      _error = "An error occurred: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
