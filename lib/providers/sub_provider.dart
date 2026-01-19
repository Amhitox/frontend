import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/quota_status.dart';
import 'package:frontend/models/subscription.dart';
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

  Future<dynamic> startSubscription(String priceId, {String? paymentMethod}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await subService.startSubscription(priceId, paymentMethod: paymentMethod);
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
    try {
      final response = await subService.confirmSubscription(
        subscriptionId,
        customerId,
      );
      await fetchQuotaStatus(); 
      await fetchSubscription();
      return response;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscription Status
  Subscription? _subscription;
  Subscription? get subscription => _subscription;

  Future<void> fetchSubscription() async {
    try {
      final response = await subService.getSubscription();
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['subscription'] != null) {
          _subscription = Subscription.fromJson(data['subscription']);
        } else {
          _subscription = null;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    }
  }

  String _userCountry = 'US';
  String _currencyCode = 'USD';
  String _currencySymbol = '\$';
  double _currencyRate = 1.0;

  String get userCountry => _userCountry;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  double get currencyRate => _currencyRate;

  Future<void> fetchUserCountryAndCurrency() async {
    try {
      final response = await Dio().get('http://ip-api.com/json');
      if (response.statusCode == 200) {
        final data = response.data;
        _userCountry = data['countryCode'] ?? 'US';
        _setCurrencyFromCountry(_userCountry);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching country: $e');
    }
  }

  void _setCurrencyFromCountry(String countryCode) {
    const Map<String, Map<String, dynamic>> currencyMap = {
      'MA': {'code': 'MAD', 'symbol': 'MAD', 'rate': 10.0},
      'FR': {'code': 'EUR', 'symbol': '€', 'rate': 0.92},
      'DE': {'code': 'EUR', 'symbol': '€', 'rate': 0.92},
      'IT': {'code': 'EUR', 'symbol': '€', 'rate': 0.92},
      'ES': {'code': 'EUR', 'symbol': '€', 'rate': 0.92},
      'GB': {'code': 'GBP', 'symbol': '£', 'rate': 0.78},
      'CA': {'code': 'CAD', 'symbol': 'CA\$', 'rate': 1.35},
      'AU': {'code': 'AUD', 'symbol': 'A\$', 'rate': 1.50},
      'JP': {'code': 'JPY', 'symbol': '¥', 'rate': 145.0},
    };

    if (currencyMap.containsKey(countryCode)) {
      final data = currencyMap[countryCode]!;
      _currencyCode = data['code'];
      _currencySymbol = data['symbol'];
      _currencyRate = data['rate'];
    } else {
      _currencyCode = 'USD';
      _currencySymbol = '\$';
      _currencyRate = 1.0;
    }
  }

  String getDisplayPrice(double usdPrice) {
    if (_currencyCode == 'USD') {
      return '\$${usdPrice.toStringAsFixed(2)}';
    }
    
    double localPrice = usdPrice * _currencyRate;
    
    if (_currencyCode == 'MAD' || _currencyCode == 'JPY') {
      return '${localPrice.toStringAsFixed(0)} $_currencySymbol';
    } else if (_currencyCode == 'EUR' || _currencyCode == 'GBP') {
       return '$_currencySymbol${localPrice.toStringAsFixed(2)}';
    }
    
    return '$_currencySymbol${localPrice.toStringAsFixed(2)}';
  }

  Future<dynamic> cancelSubscription(String subscriptionId) async {
    _isLoading = true;
    // Optimistic update
    if (_subscription != null) {
      _subscription = _subscription!.copyWith(cancelAtPeriodEnd: true);
    }
    notifyListeners();
    
    try {
      final response = await subService.cancelSubscription(subscriptionId);
      if (response != null && response.statusCode == 200) {
        await fetchSubscription(); 
      }
      return response;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
