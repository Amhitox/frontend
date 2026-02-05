import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/quota_status.dart';

import 'package:frontend/services/sub_service.dart';

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

      final response = await subService.getQuotaStatus(
        timezoneOffset: timezoneOffset,
      );
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

  Future<Map<String, dynamic>> addPriorityEmail(
    String userId,
    String email,
  ) async {
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
        if (data != null &&
            (data['quotaExceeded'] == true ||
                data['code'] == 'QUOTA_EXCEEDED')) {
          return {
            'success': false,
            'quotaExceeded': true,
            'error': data['error'] ?? 'Quota exceeded',
          };
        }
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to add priority email',
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

  Future<Map<String, dynamic>?> initiateCmiPayment({
    required double amount,
    required String userId,
    required Map<String, dynamic> userInfo,
    required String planTier,
    required String planPeriod,
    String? currency,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔵 Initiating CMI payment:');
      debugPrint('   Amount: $amount');
      debugPrint('   UserId: $userId');
      debugPrint('   PlanTier: $planTier');
      debugPrint('   PlanPeriod: $planPeriod');
      debugPrint('   Currency: $currency');

      final response = await subService.signCmiPayment(
        amount: amount,
        userId: userId,
        userInfo: userInfo,
        planTier: planTier,
        planPeriod: planPeriod,
        currency: currency,
      );

      debugPrint('🟢 CMI Response status: ${response.statusCode}');
      debugPrint('🟢 CMI Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['url'] != null) {
          return data;
        } else {
          debugPrint('🔴 CMI Response missing url: $data');
          return null;
        }
      }
      debugPrint('🔴 CMI Response not 200: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('🔴 CMI DioException: ${e.message}');
      debugPrint('🔴 CMI DioException response: ${e.response?.data}');
      debugPrint('🔴 CMI DioException status: ${e.response?.statusCode}');
      return null;
    } catch (e) {
      debugPrint('🔴 Error initiating CMI payment: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelSubscription(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await subService.cancelSubscription(userId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
