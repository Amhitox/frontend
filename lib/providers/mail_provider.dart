import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/email_message.dart';
import '../services/mail_service.dart';
import '../services/outlook_service.dart';

class MailProvider extends ChangeNotifier {
  final Dio dio;
  late MailService _mailService;
  late OutlookService _outlookService;
  
  // 'gmail' or 'outlook'
  String _currentProvider = 'gmail';
  
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

  // Track active search queries per filter
  final Map<String, String?> _activeQueries = {};
  
  // Track if the current active list is a search result
  final Map<String, bool> _isShowingSearchResults = {};
  
  // Cache validity duration (e.g., 5 minutes)
  static const Duration _cacheValidity = Duration(minutes: 5);
  static const String _boxName = 'mail_cache_v2';
  static const String _dataKeyPrefix = 'data_';
  static const String _timestampKeyPrefix = 'time_';

  MailProvider({required this.dio}) {
    _mailService = MailService(dio: dio);
    _outlookService = OutlookService(dio: dio);
    _initProvider();
  }

  Future<void> _initProvider() async {
    final box = await Hive.openBox('mail_settings');
    
    // Read the user's saved provider choice - this is set when they click Gmail or Outlook
    _currentProvider = box.get('selected_provider', defaultValue: 'gmail');
    debugPrint('🔄 [MailProvider] Loaded saved provider: $_currentProvider');
    
    notifyListeners();
  }

  bool _isConnected = false;
  
  String get currentProvider => _currentProvider;
  
  Future<void> setProvider(String provider) async {
    if (_currentProvider != provider) {
      _currentProvider = provider;
      _activeEmails.clear();
      _cachedEmails.clear(); 
      _nextPageTokens.clear();
      _activeQueries.clear();
      _isShowingSearchResults.clear();
       // Note: we might want to keep separate caches per provider in the future
       // But for now, clearing active ensures we load fresh data for the new provider.
      
      final box = await Hive.openBox('mail_settings');
      await box.put('selected_provider', provider);
      
      notifyListeners();
      checkConnection();
    }
  }

  Future<dynamic> connectGmail() => _mailService.connect();
  Future<dynamic> connectOutlook() => _outlookService.connect();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;
  
  List<EmailMessage> getEmailsForFilter(String filter) {
    return _activeEmails[filter.toLowerCase()] ?? [];
  }
  
  bool hasMoreForFilter(String filter) {
    return _nextPageTokens[filter.toLowerCase()] != null;
  }

  /// Main method to load emails for a filter
  Future<void> loadEmails({required String filter, bool forceRefresh = false, String? query}) async {
    final filterKey = filter.toLowerCase();
    
    // Update active query
    if (query != null && query.isNotEmpty) {
      _activeQueries[filterKey] = query;
    } else {
      _activeQueries.remove(filterKey);
    }
    
    final isSearching = _activeQueries[filterKey] != null;

    // If we are NOT searching, but the current active list IS search results,
    // we must clear the active list so it reloads from cache/disk/api.
    if (!isSearching && (_isShowingSearchResults[filterKey] ?? false)) {
       _activeEmails[filterKey] = [];
       _isShowingSearchResults[filterKey] = false;
       // We intentionally don't return here, we proceed to load logic
    }

    // 1. If we have active data and not forcing refresh, check if we need to reload
    // Skip this check if searching, as we always want to fetch results for the new query
    if (!isSearching && !forceRefresh && (_activeEmails[filterKey]?.isNotEmpty ?? false)) {
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
      // Skip disk load if searching
      if (!isSearching && (_activeEmails[filterKey]?.isEmpty ?? true) && !forceRefresh) {
        await _loadFromDisk(filterKey);
        
        // If we found data on disk, populate active list
        if (_cachedEmails[filterKey]?.isNotEmpty ?? false) {
           // Only use disk cache if it's NOT a search result (sanity check, disk shouldn't have search results)
           _activeEmails[filterKey] = List.from(_cachedEmails[filterKey]!);
           _isShowingSearchResults[filterKey] = false;

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
      debugPrint('🔄 [MailProvider] Fetching from API for $filterKey (Provider: $_currentProvider) Query: $query...');
      
      Map<String, dynamic>? response;
      
      if (_currentProvider == 'gmail') {
        await _mailService.initialize();
        final apiType = _getBackendType(filter);
        response = await _mailService.listMails(type: apiType, maxResults: 20, query: query);
      } else {
        await _outlookService.initialize();
        var apiType = _getBackendType(filter); 
        // Fallback: Outlook might not support 'priority' type endpoint yet, map to 'important' or 'inbox' if needed.
        if (apiType == 'priority') {
            apiType = 'important'; 
        }
        
        // Outlook service doesn't support query yet in this interface, might need update if required
        response = await _outlookService.listMails(type: apiType, maxResults: 20, query: query);
      }
      
      debugPrint('📧 [MailProvider] Raw response: $response');
      
      if (response != null && response['messages'] != null) {
        final messagesList = response['messages'] as List;
        debugPrint('📧 [MailProvider] Messages count: ${messagesList.length}');
        if (messagesList.isNotEmpty) {
          debugPrint('📧 [MailProvider] First message: ${messagesList.first}');
        }
        var newEmails = messagesList.map((data) => _parseApiMessage(data as Map<String, dynamic>)).toList();
        
        // Applying requested primary filtering: only for Gmail (Outlook doesn't use labels)
        // Skip label filtering if searching, as search results might not contain specific labels
        if (!isSearching && filterKey == 'primary' && _currentProvider == 'gmail') {
          newEmails = newEmails.where((e) => e.labelIds.contains('INBOX')).toList();
        }

        // If searching, prioritize name and email matches
        if (isSearching && query != null && query.isNotEmpty) {
           final qLower = query.toLowerCase();
           newEmails.sort((a, b) {
              // Scoring function: higher is better
              int score(EmailMessage e) {
                 if (e.senderEmail.toLowerCase() == qLower) return 100;
                 if (e.senderEmail.toLowerCase().contains(qLower)) return 80;
                 if (e.sender.toLowerCase().contains(qLower)) return 60;
                 if (e.subject.toLowerCase().contains(qLower)) return 40;
                 return 0; // Body/snippet match
              }
              
              return score(b).compareTo(score(a)); // Descending
           });
        }

        // Update caches
        // Only update disk cache if NOT searching
        if (!isSearching) {
          _cachedEmails[filterKey] = newEmails;
          _saveToDisk(filterKey);
        }
        
        _activeEmails[filterKey] = List.from(newEmails); // Reset active list to new first page
        _isShowingSearchResults[filterKey] = isSearching;

        _nextPageTokens[filterKey] = response['nextPageToken'] as String?;
        
        // Only update last fetch time if NOT searching, to prevent search results from validating the "cache" time for the filter
        if (!isSearching) {
            _lastFetchTimes[filterKey] = DateTime.now();
        }
        
        debugPrint('✅ [MailProvider] Fetched ${_activeEmails[filterKey]!.length} items for $filterKey');
      } else {
         // Empty response or error
         // If searching, this just means no results found
         if (!isSearching) {
           _cachedEmails[filterKey] = [];
         }
         _activeEmails[filterKey] = [];
         _isShowingSearchResults[filterKey] = isSearching;
         _nextPageTokens[filterKey] = null;
      }

    } catch (e) {
      debugPrint('❌ [MailProvider] Error loading emails: $e');
      _error = e.toString();
      
      // If offline or error, ensure we at least show what we have in cache
      // Only fallback to cache if NOT searching
      if (!isSearching && _activeEmails[filterKey] == null && _cachedEmails[filterKey] != null) {
        _activeEmails[filterKey] = List.from(_cachedEmails[filterKey]!);
        _isShowingSearchResults[filterKey] = false;
      }
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more emails (Pagination) - DOES NOT persist to disk
  Future<void> loadMore({required String filter}) async {
    final filterKey = filter.toLowerCase();
    final query = _activeQueries[filterKey];
    
    if (_isLoading || _nextPageTokens[filterKey] == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final apiType = _getBackendType(filter);
      final pageToken = _nextPageTokens[filterKey];
      
      debugPrint('🔄 [MailProvider] Loading page 2+ for $filterKey (token: $pageToken)...');
      
      Map<String, dynamic>? response;
      if (_currentProvider == 'gmail') {
         response = await _mailService.listMails(
          type: apiType, 
          maxResults: 20, 
          pageToken: pageToken,
          query: query
        );
      } else {
         response = await _outlookService.listMails(
          type: apiType, 
          maxResults: 20, 
          pageToken: pageToken
        );
      }
      
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

  Future<void> disconnect() async {
    if (_currentProvider == 'gmail') {
      await _mailService.disconnect();
    } else {
      await _outlookService.disconnect();
    }
    await resetLocalState();
  }

  Future<void> resetLocalState() async {
    _mailService.clearLocalData();
    _outlookService.clearLocalData();
    await clearCache();
    _isConnected = false;
    notifyListeners();
  }

  Future<void> checkConnection() async {
    Map<String, dynamic>? tokenData;
    
    if (_currentProvider == 'gmail') {
      await _mailService.initialize();
      tokenData = await _mailService.checkTokens();
    } else {
      await _outlookService.initialize();
      tokenData = await _outlookService.checkTokens();
    }
    
    if (tokenData != null && tokenData['hasTokens'] == true) {
      _isConnected = true;
    } else {
      _isConnected = false;
    }
    notifyListeners();
  }

  String _getBackendType(String filter) {
    switch (filter.toLowerCase()) {
      case 'primary': return 'primary';
      case 'priority': return 'priority';
      case 'sent': return 'sent';
      case 'drafts': return 'drafts';
      case 'important': return 'important';
      case 'trash': return 'trash';
      case 'spam': return 'spam';
      case 'other': return 'other';
      default: return 'primary';
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
    final isUnread = data['isUnread'] as bool? ?? labelIds.contains('UNREAD');
    final isImportant = data['isImportant'] as bool? ?? labelIds.contains('IMPORTANT');
    final isSpam = data['isSpam'] as bool? ?? labelIds.contains('SPAM');
    
    final summary = data['summary'] as String?;

    final emailHeaders = EmailHeaders(
      subject: headers['subject'] as String?,
      from: headers['from'] as String?,
      to: headers['to'] as String?,
      date: headers['date'] as String?,
    );

    List<EmailAttachment>? attachments;
    final attachmentsData = data['attachments'] as List<dynamic>?;
    if (attachmentsData != null && attachmentsData.isNotEmpty) {
      attachments = attachmentsData
          .map((a) => EmailAttachment.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    final hasAttachments = attachments != null && attachments.isNotEmpty;

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
      isImportant: isImportant,
      isSpam: isSpam,
      labelIds: labelIds.map((e) => e.toString()).toList(),
      hasAttachments: hasAttachments,
      attachments: attachments,
      headers: emailHeaders,
      summary: summary,
    );
  }

  /// Mark email as read and update local state
  Future<bool> markAsRead(String messageId) async {
    bool success;
    if (_currentProvider == 'gmail') {
      success = await _mailService.markAsRead(messageId);
    } else {
      success = await _outlookService.markAsRead(messageId);
    }
    
    if (success) {
      _updateMessageLocally(messageId, (msg) => msg.copyWith(isUnread: false));
    }
    return success;
  }

  /// Mark email as unread and update local state
  Future<bool> markAsUnread(String messageId) async {
    bool success;
    if (_currentProvider == 'gmail') {
      success = await _mailService.markAsUnread(messageId);
    } else {
       success = await _outlookService.markAsUnread(messageId);
    }

    if (success) {
      _updateMessageLocally(messageId, (msg) => msg.copyWith(isUnread: true));
    }
    return success;
  }

  /// Delete email and remove from local state
  Future<bool> deleteEmail(String messageId) async {
    bool success;
    if (_currentProvider == 'gmail') {
      success = await _mailService.deleteEmail(messageId);
    } else {
      success = await _outlookService.deleteEmail(messageId);
    }

    if (success) {
      // Remove from all active lists
      for (var key in _activeEmails.keys) {
        _activeEmails[key]?.removeWhere((msg) => msg.id == messageId);
      }
      
      // Update cache
      for (var key in _cachedEmails.keys) {
        _cachedEmails[key]?.removeWhere((msg) => msg.id == messageId);
        await _saveToDisk(key);
      }
      notifyListeners();
    }
    return success;
  }

  /// Manually summarize an email
  Future<String?> summarizeEmail(String messageId) async {
    Map<String, dynamic>? result;
    if (_currentProvider == 'gmail') {
      result = await _mailService.summarizeEmail(messageId);
    } else {
      result = await _outlookService.summarizeEmail(messageId);
    }

    if (result != null && result['summary'] != null) {
      String summaryText = '';
      if (result['summary'] is Map) {
        final summaryMap = result['summary'] as Map;
        String? extracted = summaryMap['content']?.toString() ?? 
                           summaryMap['text']?.toString() ?? 
                           summaryMap['summary']?.toString();
                           
        if (extracted == null && summaryMap.values.isNotEmpty) {
          extracted = summaryMap.values.first.toString();
        }
        summaryText = extracted ?? '';
      } else {
        summaryText = result['summary'].toString();
      }

      if (summaryText.isNotEmpty) {
        _updateMessageLocally(messageId, (msg) => msg.copyWith(summary: summaryText));
        return summaryText;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getEmailDetails(String id) async {
    if (_currentProvider == 'gmail') {
      await _mailService.initialize();
      return await _mailService.getEmailDetails(id);
    } else {
      await _outlookService.initialize();
      return await _outlookService.getEmailDetails(id);
    }
  }

  Future<Map<String, dynamic>?> createDraft(
    String to,
    String subject,
    String body,
    List<Map<String, dynamic>>? attachments, {
    String? cc,
    String? bcc,
  }) async {
    if (_currentProvider == 'gmail') {
      return await _mailService.createDraft(to, subject, body, attachments, cc: cc, bcc: bcc);
    } else {
      return await _outlookService.createDraft(to, subject, body, attachments, cc: cc, bcc: bcc);
    }
  }

  Future<Map<String, dynamic>?> sendEmail(
    String to,
    String subject,
    String body,
    List<Map<String, dynamic>>? attachments, {
    String? cc,
    String? bcc,
  }) async {
      if (_currentProvider == 'gmail') {
         // MailService uses sendEmailWithBytes
         return await _mailService.sendEmailWithBytes(to, subject, body, attachments, cc: cc, bcc: bcc);
      } else {
         // OutlookService uses byteAttachments
         // Use named parameters as per OutlookService definition
         return await _outlookService.sendEmail(
             to: to, 
             subject: subject, 
             body: body, 
             byteAttachments: attachments, 
             cc: cc, 
             bcc: bcc
         );
      }
  }

  void _updateMessageLocally(String id, EmailMessage Function(EmailMessage) updateFn) {
    bool changed = false;
    for (var key in _activeEmails.keys) {
      final list = _activeEmails[key];
      if (list == null) continue;
      
      final index = list.indexWhere((m) => m.id == id);
      if (index != -1) {
        list[index] = updateFn(list[index]);
        changed = true;
      }
    }
    
    if (changed) notifyListeners();
  }
  Future<Map<String, dynamic>?> refineEmail(
    String currentSubject,
    String currentBody,
    String instruction,
  ) async {
    if (_currentProvider == 'gmail') {
      return await _mailService.refineEmail(currentSubject, currentBody, instruction);
    } else {
      return await _outlookService.refineEmail(currentSubject, currentBody, instruction);
    }
  }

  Future<void> downloadAttachment(
    String messageId,
    String attachmentId,
    String filename,
  ) async {
    if (_currentProvider == 'gmail') {
      await _mailService.downloadAttachment(messageId, attachmentId, filename);
    } else {
      await _outlookService.downloadAttachment(messageId, attachmentId, filename);
    }
  }

  Future<String?> getGmailAccessToken() async {
    await _mailService.initialize();
    return _mailService.accessToken;
  }

  Future<Map<String, dynamic>?> getGmailTokens() async {
    await _mailService.initialize();
    return await _mailService.checkTokens();
  }
}
