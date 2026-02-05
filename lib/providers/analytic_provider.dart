import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/analytic_data.dart';
import 'package:frontend/services/analytic_service.dart';
import 'package:frontend/services/pdf_service.dart';
// import 'package:permission_handler/permission_handler.dart'; // Maybe needed for Android < 10 or generic file access

class AnalyticProvider extends ChangeNotifier {
  final AnalyticService _analyticService;

  AnalyticProvider({required Dio dio})
    : _analyticService = AnalyticService(dio: dio);

  bool _isLoading = false;
  String? _error;
  final Map<String, AnalyticData> _cache = {};

  bool get isLoading => _isLoading;
  String? get error => _error;

  AnalyticData? getData(String period) => _cache[period];

  Future<void> fetchAnalytics(
    String period, {
    bool forceRefresh = false,
  }) async {
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

  Future<String?> generateAndDownloadReport(String period) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = _cache[period];
      if (data == null) {
        await fetchAnalytics(period);
        if (_cache[period] == null) {
          _error = "No data available to generate report";
          return null;
        }
      }

      final pdfService = PdfService();
      final file = await pdfService.generateAnalyticsReport(
        _cache[period]!,
        period,
      );

      return file.path;
    } catch (e) {
      _error = "Report generation failed: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
