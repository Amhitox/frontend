import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/email_message.dart';
import '../services/mail_service.dart';

class MailProvider extends ChangeNotifier {
  final Dio dio;
  late MailService _mailService;
  
  // Cache for first 20 items per filter (Persisted)
  final Map<String, List<EmailMessage>> _cachedEmails = {};
  
  // Active list being displayed (Memory only, includes loaded more items)
  final Map<String, List<EmailMessage>> _activeEmails = {};
  
  // Pagination tokens per filter
  final Map<String, String?> _nextPageTokens = {};
  
  bool _isLoading = false;
  String? _error;
  
  // Track last fetch time per filter
  final Map<String, DateTime> _lastFetchTimes = {};
  
  // Cache validity duration (e.g., 5 minutes)
  static const Duration _cacheValidity = Duration(minutes: 5);
  static const String _boxName = 'mail_cache_v2';
  static const String _dataKeyPrefix = 'data_';
  static const String _timestampKeyPrefix = 'time_';

  MailProvider({required this.dio}) {
    _mailService = MailService(dio: dio);
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<EmailMessage> getEmailsForFilter(String filter) {
    return _activeEmails[filter.toLowerCase()] ?? [];
  }
  
  bool hasMoreForFilter(String filter) {
    return _nextPageTokens[filter.toLowerCase()] != null;
  }

  /// Main method to load emails for a filter
  Future<void> loadEmails({required String filter, bool forceRefresh = false}) async {
    final filterKey = filter.toLowerCase();
    
    // 1. If we have active data and not forcing refresh, check if we need to reload
    if (!forceRefresh && (_activeEmails[filterKey]?.isNotEmpty ?? false)) {
      if (_isCacheValid(filterKey)) {
        debugPrint('✅ [MailProvider] Using valid memory cache for $filterKey');
        return;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 2. Load from disk first if memory is empty
      if ((_activeEmails[filterKey]?.isEmpty ?? true) && !forceRefresh) {
        await _loadFromDisk(filterKey);
        
        // If we found data on disk, populate active list
        if (_cachedEmails[filterKey]?.isNotEmpty ?? false) {
           _activeEmails[filterKey] = List.from(_cachedEmails[filterKey]!);
           debugPrint('✅ [MailProvider] Loaded disk cache for $filterKey (${_cachedEmails[filterKey]!.length} items)');
           notifyListeners();
           
           // If cache is valid, stop here
           if (_isCacheValid(filterKey)) {
             _isLoading = false;
             notifyListeners();
             return;
           } else {
             debugPrint('⚠️ [MailProvider] Disk cache stale for $filterKey, refreshing background...');
           }
        }
      }

      // 3. Fetch from API
      debugPrint('🔄 [MailProvider] Fetching from API for $filterKey...');
      await _mailService.initialize();

      // Convert UI filter to API type
      final apiType = _getBackendType(filter);
      
      final response = await _mailService.listMails(type: apiType, maxResults: 20);
      
      if (response != null && response['messages'] != null) {
        final messagesList = response['messages'] as List;
        final newEmails = messagesList.map((data) => _parseApiMessage(data as Map<String, dynamic>)).toList();
        
        // Update caches
        _cachedEmails[filterKey] = newEmails;
        _activeEmails[filterKey] = List.from(newEmails); // Reset active list to new first page
        _nextPageTokens[filterKey] = response['nextPageToken'] as String?;
        _lastFetchTimes[filterKey] = DateTime.now();
        
        // Save to disk
        await _saveToDisk(filterKey);
        
        debugPrint('✅ [MailProvider] Fetched ${_activeEmails[filterKey]!.length} items for $filterKey');
      } else {
         // Empty response or error
         _cachedEmails[filterKey] = [];
         _activeEmails[filterKey] = [];
         _nextPageTokens[filterKey] = null;
      }

    } catch (e) {
      debugPrint('❌ [MailProvider] Error loading emails: $e');
      _error = e.toString();
      
      // If offline or error, ensure we at least show what we have in cache
      if (_activeEmails[filterKey] == null && _cachedEmails[filterKey] != null) {
        _activeEmails[filterKey] = List.from(_cachedEmails[filterKey]!);
      }
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more emails (Pagination) - DOES NOT persist to disk
  Future<void> loadMore({required String filter}) async {
    final filterKey = filter.toLowerCase();
    
    if (_isLoading || _nextPageTokens[filterKey] == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final apiType = _getBackendType(filter);
      final pageToken = _nextPageTokens[filterKey];
      
      debugPrint('🔄 [MailProvider] Loading page 2+ for $filterKey (token: $pageToken)...');
      
      final response = await _mailService.listMails(
        type: apiType, 
        maxResults: 20, 
        pageToken: pageToken
      );
      
      if (response != null && response['messages'] != null) {
        final messagesList = response['messages'] as List;
        final moreEmails = messagesList.map((data) => _parseApiMessage(data as Map<String, dynamic>)).toList();
        
        // Append to active list ONLY
        if (_activeEmails[filterKey] == null) {
          _activeEmails[filterKey] = [];
        }
        _activeEmails[filterKey]!.addAll(moreEmails);
        
        // Update token
        _nextPageTokens[filterKey] = response['nextPageToken'] as String?;
        
        debugPrint('✅ [MailProvider] Loaded ${moreEmails.length} more items. Total: ${_activeEmails[filterKey]!.length}');
      } else {
        _nextPageTokens[filterKey] = null; // No more items
      }
      
    } catch (e) {
      debugPrint('❌ [MailProvider] Error loading more: $e');
      // Don't set global error for pagination failure, just stop loading
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Helper: Check if cache is validity
  bool _isCacheValid(String key) {
    final lastFetch = _lastFetchTimes[key];
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < _cacheValidity;
  }

  /// Helper: Load specific filter from Hive
  Future<void> _loadFromDisk(String key) async {
    try {
      final box = await Hive.openBox(_boxName);
      
      // Load timestamp
      final timestamp = box.get('${_timestampKeyPrefix}$key');
      if (timestamp != null) {
        _lastFetchTimes[key] = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      // Load data
      final List<dynamic>? cachedList = box.get('${_dataKeyPrefix}$key');
      
      if (cachedList != null) {
        _cachedEmails[key] = cachedList.map((e) {
           if (e is String) {
             return EmailMessage.fromJson(jsonDecode(e));
           } else {
             return EmailMessage.fromJson(Map<String, dynamic>.from(e));
           }
        }).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [MailProvider] Failed to load from disk: $e');
    }
  }

  /// Helper: Save specific filter to Hive
  Future<void> _saveToDisk(String key) async {
    try {
      final listToSave = _cachedEmails[key];
      if (listToSave == null) return;
      
      final box = await Hive.openBox(_boxName);
      
      // Store timestamp
      if (_lastFetchTimes[key] != null) {
        await box.put('${_timestampKeyPrefix}$key', _lastFetchTimes[key]!.millisecondsSinceEpoch);
      }

      // Store data
      final jsonList = listToSave.map((e) => e.toJson()).toList();
      await box.put('${_dataKeyPrefix}$key', jsonList);
      
    } catch (e) {
      debugPrint('⚠️ [MailProvider] Failed to save to disk: $e');
    }
  }

  Future<void> clearCache() async {
    _cachedEmails.clear();
    _activeEmails.clear();
    _nextPageTokens.clear();
    _lastFetchTimes.clear();
    
    final box = await Hive.openBox(_boxName);
    await box.clear();
    notifyListeners();
  }

  String _getBackendType(String filter) {
    switch (filter.toLowerCase()) {
      case 'inbox': return 'inbox';
      case 'sent': return 'sent';
      case 'drafts': return 'drafts';
      case 'important': return 'important';
      case 'trash': return 'trash';
      case 'other': return 'other';
      default: return 'inbox';
    }
  }

  /// Parser for API response
  EmailMessage _parseApiMessage(Map<String, dynamic> data) {
    final headers = data['headers'] as Map<String, dynamic>? ?? {};

    String sender = 'Unknown Sender';
    String senderEmail = '';

    final fromHeader = headers['from'] as String? ?? '';
    if (fromHeader.isNotEmpty) {
      if (fromHeader.contains('<') && fromHeader.contains('>')) {
        final parts = fromHeader.split('<');
        sender = parts[0].trim();
        senderEmail = parts[1].replaceAll('>', '').trim();
      } else {
        senderEmail = fromHeader;
        sender = fromHeader.split('@').first;
      }
    }

    final subject = headers['subject'] as String? ?? '(No Subject)';
    final snippet = data['snippet'] as String? ?? '';
    final body = data['body'] as String? ?? snippet;

    DateTime date = DateTime.now();
    final dateString = data['date'] as String? ?? headers['date'] as String?;
    if (dateString != null) {
      try {
        date = DateTime.parse(dateString);
      } catch (e) {
        debugPrint('❌ [MailProvider] Error parsing date: $dateString');
      }
    }

    final labelIds = data['labelIds'] as List<dynamic>? ?? [];
    final isUnread = labelIds.contains('UNREAD');
    final hasAttachments = data['hasAttachments'] == true;
    
    final summary = data['summary'] as String?;

    // Create EmailHeaders object
    final emailHeaders = EmailHeaders(
      subject: headers['subject'] as String?,
      from: headers['from'] as String?,
      to: headers['to'] as String?,
      date: headers['date'] as String?,
    );

    return EmailMessage(
      id: data['id'] as String? ?? '',
      threadId: data['threadId'] as String? ?? data['id'] as String? ?? '',
      draftId: data['draftId'] as String?,
      sender: sender,
      senderEmail: senderEmail,
      subject: subject,
      snippet: snippet,
      body: body,
      date: date,
      isUnread: isUnread,
      labelIds: labelIds.map((e) => e.toString()).toList(),
      hasAttachments: hasAttachments,
      attachments: null,
      headers: emailHeaders,
      summary: summary,
    );
  }
}
