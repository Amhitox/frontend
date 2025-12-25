import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/quota_status.dart';
import 'package:frontend/services/sub_service.dart';
import 'dart:convert';
class SubProvider extends ChangeNotifier {
  final SubService subService;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  QuotaStatus? _quotaStatus;
  QuotaStatus? get quotaStatus => _quotaStatus;

  List<String> _priorityEmails = [];
  List<String> get priorityEmails => _priorityEmails;

  SubProvider({required Dio dio}) : subService = SubService(dio: dio);

  Future<void> fetchQuotaStatus() async {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final timezoneOffset = _formatTimezoneOffset(offset);
      
      final response = await subService.getQuotaStatus(timezoneOffset: timezoneOffset);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          _quotaStatus = QuotaStatus.fromJson(data['data']);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching quota: $e');
    }
  }

  Future<void> fetchPriorityEmails(String userId) async {
    try {
      final response = await subService.getPriorityEmails(userId);
      if (response.statusCode == 200) {
        _priorityEmails = List<String>.from(response.data['priorityEmails']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching priority emails: $e');
    }
  }

  Future<Map<String, dynamic>> addPriorityEmail(String userId, String email) async {
    try {
      final response = await subService.addPriorityEmail(userId, email);
      if (response.statusCode == 200) {
        await fetchPriorityEmails(userId);
        await fetchQuotaStatus();
        return {'success': true};
      }
      return {'success': false, 'error': 'Unexpected error'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data != null && (data['quotaExceeded'] == true || data['code'] == 'QUOTA_EXCEEDED')) {
          return {
            'success': false,
            'quotaExceeded': true,
            'error': data['error'] ?? 'Quota exceeded'
          };
        }
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to add priority email'
      };
    }
  }

  Future<void> removePriorityEmail(String userId, String email) async {
    try {
      await subService.removePriorityEmail(userId, email);
      if (_priorityEmails.contains(email)) {
        _priorityEmails.remove(email);
        notifyListeners();
      }
      await fetchQuotaStatus();
    } catch (e) {
      debugPrint('Error removing priority email: $e');
      rethrow;
    }
  }

  String _formatTimezoneOffset(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes.remainder(60).abs();
    final sign = totalMinutes >= 0 ? '+' : '-';
    return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<dynamic> startSubscription(String priceId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await subService.startSubscription(priceId);
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
    await fetchQuotaStatus(); // Refresh quota after subscription change
    return response;
  }
}
