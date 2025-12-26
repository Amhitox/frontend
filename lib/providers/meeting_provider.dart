import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/calendar_manager.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/meeting_location.dart';
import 'package:frontend/services/meeting_service.dart';
import 'package:frontend/providers/sub_provider.dart';
import 'package:provider/provider.dart' as provider;
import 'package:frontend/models/attendee.dart';

class MeetingProvider extends ChangeNotifier {
  final MeetingService meeting;
  final CalendarManager _calendarManager = CalendarManager();

  bool _isLoading = false;
  bool _isOnline = true;
  bool _isSyncing = false;
  bool _syncInProgress = false;
  DateTime? _lastSyncTime;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Add a set to track meetings currently being synced
  final Set<String> _syncingMeetings = <String>{};

  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  MeetingProvider({required Dio dio}) : meeting = MeetingService(dio: dio);

  Future<void> init(String userId) async {
    await _calendarManager.init(userId);
    await _checkConnectivity();
    _startConnectivityMonitoring();

    if (_isOnline) {
      Future.delayed(const Duration(seconds: 1), () {
        _performFullSync();
      });
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);

      print(
        'MeetingProvider: Connectivity changed - Online: $_isOnline, Was offline: $wasOffline',
      );

      if (wasOffline && _isOnline && !_syncInProgress) {
        final now = DateTime.now();
        if (_lastSyncTime == null ||
            now.difference(_lastSyncTime!).inSeconds > 10) {
          print('MeetingProvider: Scheduling sync in 2 seconds');
          Timer(const Duration(seconds: 2), () {
            if (_isOnline && !_syncInProgress) {
              print('MeetingProvider: Starting full sync');
              _performFullSync();
            }
          });
        }
      }

      notifyListeners();
    });
  }

  Future<void> _performFullSync() async {
    if (!_isOnline || _syncInProgress) {
      print(
        'MeetingProvider: Sync skipped - offline: ${!_isOnline}, in progress: $_syncInProgress',
      );
      return;
    }

    print('MeetingProvider: Starting full sync process');
    _syncInProgress = true;
    _isSyncing = true;
    _lastSyncTime = DateTime.now();
    notifyListeners();

    try {
      print('MeetingProvider: Syncing deleted meetings');
      await _syncDeletedMeetings();

      print('MeetingProvider: Syncing unsynced meetings');
      await syncUnsyncedMeetings();

      print('MeetingProvider: Syncing from server');
      await syncAllFromServer();

      print('MeetingProvider: Full sync completed successfully');

      print('MeetingProvider: Full sync completed successfully');
    } catch (e) {
      print('MeetingProvider: Full sync failed: $e');
    } finally {
      _isSyncing = false;
      _syncInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _syncDeletedMeetings() async {
    final deletedMeetings = _calendarManager.getDeletedMeetings();

    for (final meetingId in deletedMeetings) {
      if (meetingId.startsWith('temp_')) {
        await _calendarManager.clearDeletedMeeting(meetingId);
        continue;
      }

      try {
        await meeting.deleteMeeting(meetingId);
        await _calendarManager.clearDeletedMeeting(meetingId);
      } catch (e) {
        print("MeetingProvider: Failed to sync deleted meeting $meetingId: $e");
      }
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult.any(
      (result) => result != ConnectivityResult.none,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<String> addMeeting(
    String title,
    String description,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
    List<Attendee> attendees,
    MeetingLocation location,
  ) async {
    String meetingId;

    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Get timezone offset from the actual datetime (not DateTime.now())
    // This ensures we use the correct offset for the specific date/time
    final timezoneOffset = _formatTimezoneOffset(startDateTime.timeZoneOffset);

    if (_isOnline) {
      try {
        final response = await meeting.addMeeting(
          title,
          description,
          startDateTime.toIso8601String(),
          endDateTime.toIso8601String(),
          attendees,
          location.toString().split('.').last,
          timezoneOffset,
        );

        if (response.statusCode == 201) {
          final data = response.data;
          if (data is Map && data.containsKey('data')) {
             if (data['data'] is Map && data['data'].containsKey('event')) {
                meetingId = data['data']['event']['eventId'];
             } else {
                 meetingId = '';
             }
          } else if (data is Map && data.containsKey('event')) {
             meetingId = data['event']['eventId'];
          } else {
            meetingId = '';
          }

          if (meetingId.isEmpty) {
             print("MeetingProvider: Meeting ID not found in response: $data");
            throw Exception('No meeting ID returned from server');
          }

          final newMeeting = Meeting(
            id: meetingId,
            title: title,
            description: description,
            date: date.toIso8601String().split('T').first, 
            startTime: _formatTimeOfDay(startTime), 
            endTime: _formatTimeOfDay(endTime), 
            attendees: attendees,
            location: location,
          );

          await _calendarManager.addOrUpdateMeeting(newMeeting, isSynced: true);
        } else {
          throw Exception(
            'Server returned ${response.statusCode}: ${response.data}',
          );
        }
      } on DioException catch (e) {
        // Rethrow validation errors and quota exceeded errors
        if (e.response?.statusCode == 400 || 
            e.response?.statusCode == 403 || 
            e.response?.statusCode == 409) {
          final data = e.response?.data;
          
          // Check for quota exceeded
          if (data is Map && data['code'] == 'QUOTA_EXCEEDED') {
            print("MeetingProvider: Quota exceeded: ${data['error']}");
            rethrow;
          }
          
          // Check for validation errors (like invalid time range)
          if (data is Map && (data['code'] == 'INVALID_TIME_RANGE' || 
                              data['code'] == 'INVALID_DATE' ||
                              data['code'] == 'VALIDATION_ERROR')) {
             print("MeetingProvider: Validation error: ${data['details'] ?? data['error']}");
             rethrow;
          }
          
           // Generic fallback for other 409s if needed, or just rethrow all 409s
           if (e.response?.statusCode == 409) {
              rethrow;
           }
        }
        
        // Only fallback to local creation for network errors or server errors (5xx)
        // that are not explicit validation rejections
        meetingId = await _createLocalMeeting(
          title,
          description,
          date,
          startTime,
          endTime,
          attendees,
          location,
        );
      } catch (e) {
        meetingId = await _createLocalMeeting(
          title,
          description,
          date,
          startTime,
          endTime,
          attendees,
          location,
        );
      }
    } else {
      meetingId = await _createLocalMeeting(
        title,
        description,
        date,
        startTime,
        endTime,
        attendees,
        location,
      );
    }

    notifyListeners();
    return meetingId;
  }

  Future<String> _createLocalMeeting(
    String title,
    String description,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
    List<Attendee> attendees,
    MeetingLocation location,
  ) async {
    final newMeeting = Meeting(
      id: null,
      title: title,
      description: description,
      date: date.toIso8601String().split('T').first, // Store date only
      startTime: _formatTimeOfDay(startTime), // Store time as string
      endTime: _formatTimeOfDay(endTime), // Store time as string
      attendees: attendees,
      location: location,
    );

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final meetingWithTempId = newMeeting.copyWith(id: tempId);

    await _calendarManager.addOrUpdateMeeting(
      meetingWithTempId,
      isSynced: false,
    );
    return tempId;
  }

  List<Meeting> getMeetings(String date) {
    final localMeetings = _calendarManager.getMeetingOfDate(
      DateTime.parse(date),
    );
    // Don't modify state or notify listeners in a getter-like method
    return localMeetings;
  }

  Future<void> syncAllFromServer() async {
    if (!_isOnline) return;

    try {
      print('MeetingProvider: Syncing all meetings from server');
      final response = await meeting.getAllMeetings();
      
      print('MeetingProvider: Response status: ${response.statusCode}');
      print('MeetingProvider: Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        List<dynamic> jsonList = [];
        if (response.data is Map && response.data.containsKey('events')) {
             jsonList = response.data["events"] as List<dynamic>;
        } else if (response.data is List) {
             jsonList = response.data as List<dynamic>;
        } else if (response.data is Map && response.data.containsKey('data')) {
             final data = response.data['data'];
             if (data is Map && data.containsKey('events')) {
                  jsonList = data['events'] as List<dynamic>;
             }
        }
        
        print('MeetingProvider: Parsed ${jsonList.length} events from response');

        if (jsonList.isNotEmpty) {
           final serverMeetings =
               jsonList.map((json) => Meeting.fromJson(json)).toList();

           print(
             'MeetingProvider: Fetched ${serverMeetings.length} meetings from server',
           );
           await _calendarManager.syncMeetingsFromServer(serverMeetings);
           notifyListeners();
        } else {
            print('MeetingProvider: No events found in response data structure: ${response.data}');
        }
      }
    } catch (e, stackTrace) {
      print('MeetingProvider: Error in syncAllFromServer: $e');
      print('MeetingProvider: Stack trace: $stackTrace');
    }
  }

  Future<void> updateMeeting(
    String id,
    String title,
    String description,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
    List<Attendee> attendees,
    MeetingLocation location,
  ) async {
    final existingMeeting = _calendarManager.getMeetingById(id);
    if (existingMeeting == null) return;

    // Combine date and time for API (in local timezone)
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Get timezone offset from the actual datetime (not DateTime.now())
    // This ensures we use the correct offset for the specific date/time
    final timezoneOffset = _formatTimezoneOffset(startDateTime.timeZoneOffset);

    final updatedMeeting = existingMeeting.copyWith(
      title: title,
      description: description,
      date: date.toIso8601String().split('T').first, // Store date only
      startTime: _formatTimeOfDay(startTime), // Store time as string
      endTime: _formatTimeOfDay(endTime), // Store time as string
      attendees: attendees,
      location: location,
    );

    if (_isOnline) {
      try {
        await meeting.updateMeeting(
          id,
          title,
          description,
          startDateTime.toIso8601String(),
          endDateTime.toIso8601String(),
          attendees,
          location.toString().split('.').last,
          timezoneOffset,
        );

        await _calendarManager.addOrUpdateMeeting(
          updatedMeeting,
          isSynced: true,
        );
      } catch (e) {
        await _calendarManager.addOrUpdateMeeting(
          updatedMeeting,
          isSynced: false,
        );
      }
    } else {
      await _calendarManager.addOrUpdateMeeting(
        updatedMeeting,
        isSynced: false,
      );
    }

    notifyListeners();
  }

  Future<void> deleteMeeting(String id) async {
    final isTempId = id.startsWith('temp_');
    if (_isOnline && !isTempId) {
      try {
        await meeting.deleteMeeting(id);
        await _calendarManager.deleteMeeting(id);
      } catch (e) {
        await _calendarManager.deleteMeeting(id);
      }
    } else {
      await _calendarManager.deleteMeeting(id);
    }

    notifyListeners();
  }

  Future<void> syncUnsyncedMeetings() async {
    if (!_isOnline) {
      return;
    }

    final unsyncedMeetings = _calendarManager.getAllUnsyncedMeetings();

    final List<Meeting> tempMeetings = [];
    final List<Meeting> existingMeetings = [];

    for (final meeting in unsyncedMeetings) {
      if (meeting.id!.startsWith('temp_')) {
        tempMeetings.add(meeting);
      } else {
        existingMeetings.add(meeting);
      }
    }

    for (final meeting in tempMeetings) {
      if (_syncingMeetings.contains(meeting.id!)) {
        continue;
      }

      _syncingMeetings.add(meeting.id!);

      try {
        // Parse stored date and time back to DateTime and TimeOfDay
        final meetingDate = DateTime.parse(
          meeting.date ?? DateTime.now().toIso8601String().split('T').first,
        );
        final startTime = _parseTimeOfDay(meeting.startTime ?? '09:00 AM');
        final endTime = _parseTimeOfDay(meeting.endTime ?? '10:00 AM');

        final startDateTime = DateTime(
          meetingDate.year,
          meetingDate.month,
          meetingDate.day,
          startTime.hour,
          startTime.minute,
        );
        final endDateTime = DateTime(
          meetingDate.year,
          meetingDate.month,
          meetingDate.day,
          endTime.hour,
          endTime.minute,
        );

        // Get timezone offset from the actual datetime (not DateTime.now())
        final timezoneOffset = _formatTimezoneOffset(startDateTime.timeZoneOffset);

        final response = await this.meeting.addMeeting(
          meeting.title ?? '',
          meeting.description ?? '',
          startDateTime.toIso8601String(),
          endDateTime.toIso8601String(),
          meeting.attendees ?? [],
          meeting.location?.toString().split('.').last ?? 'online',
          timezoneOffset,
        );

        if (response.statusCode == 201) {
          String? serverMeetingId;
          final data = response.data;
          
          if (data is Map && data.containsKey('data')) {
             if (data['data'] is Map && data['data'].containsKey('event')) {
                serverMeetingId = data['data']['event']['eventId'];
             }
          } else if (data is Map && data.containsKey('event')) {
             serverMeetingId = data['event']['eventId'];
          }

          if (serverMeetingId == null || serverMeetingId.toString().isEmpty) {
             print("MeetingProvider: Could not extract eventId from sync response: $data");
          } else {
            await _calendarManager.deleteMeeting(meeting.id!);
            final updatedMeeting = meeting.copyWith(id: serverMeetingId);
            await _calendarManager.addOrUpdateMeeting(
              updatedMeeting,
              isSynced: true,
            );
          }
        } else {}
      } finally {
        _syncingMeetings.remove(meeting.id!);
      }
    }

    for (final meeting in existingMeetings) {
      if (_syncingMeetings.contains(meeting.id!)) {
        continue;
      }

      _syncingMeetings.add(meeting.id!);

      try {
        // Parse stored date and time back to DateTime and TimeOfDay
        final meetingDate = DateTime.parse(
          meeting.date ?? DateTime.now().toIso8601String().split('T').first,
        );
        final startTime = _parseTimeOfDay(meeting.startTime ?? '09:00 AM');
        final endTime = _parseTimeOfDay(meeting.endTime ?? '10:00 AM');

        final startDateTime = DateTime(
          meetingDate.year,
          meetingDate.month,
          meetingDate.day,
          startTime.hour,
          startTime.minute,
        );
        final endDateTime = DateTime(
          meetingDate.year,
          meetingDate.month,
          meetingDate.day,
          endTime.hour,
          endTime.minute,
        );

        // Get timezone offset from the actual datetime (not DateTime.now())
        final timezoneOffset = _formatTimezoneOffset(startDateTime.timeZoneOffset);

        final response = await this.meeting.updateMeeting(
          meeting.id!,
          meeting.title ?? '',
          meeting.description ?? '',
          startDateTime.toIso8601String(),
          endDateTime.toIso8601String(),
          meeting.attendees ?? [],
          meeting.location?.toString().split('.').last ?? 'online',
          timezoneOffset,
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
            await _calendarManager.markMeetingAsSynced(meeting.id!);
        } else {
             print('MeetingProvider: Failed to sync updated meeting ${meeting.id}. Status: ${response.statusCode}');
        }
      } finally {
        _syncingMeetings.remove(meeting.id!);
      }
    }
  }

  Future<void> onConnectivityChanged() async {
    print('MeetingProvider: onConnectivityChanged called');
    _checkConnectivity();
    if (_isOnline && !_syncInProgress) {
      print('MeetingProvider: Online and not syncing, scheduling sync');
      Timer(const Duration(seconds: 1), () {
        if (_isOnline && !_syncInProgress) {
          print('MeetingProvider: Timer triggered, starting sync');
          _performFullSync();
        }
      });
    } else {
      print(
        'MeetingProvider: Not syncing - Online: $_isOnline, In progress: $_syncInProgress',
      );
    }
  }

  void debugSyncStatus() {}

  Future<void> forceSync() async {
    _checkConnectivity();
    if (_isOnline && !_syncInProgress) {
      await _performFullSync();
    } else if (_syncInProgress) {
    } else {}
  }

  Future<void> clearAndResync() async {
    _isSyncing = true;
    notifyListeners();

    await _calendarManager.clearAllMeetings();
    await forceSync();

    _isSyncing = false;
    notifyListeners();
  }

  Future<void> cleanupTempMeetings() async {
    final allMeetings = _calendarManager.getAllMeetings();
    final tempMeetings =
        allMeetings.where((m) => m.id!.startsWith('temp_')).toList();

    for (final meeting in tempMeetings) {
      await _calendarManager.deleteMeeting(meeting.id!);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;

    if (hour == 0) {
      return '12:${minute.toString().padLeft(2, '0')} AM';
    } else if (hour < 12) {
      return '$hour:${minute.toString().padLeft(2, '0')} AM';
    } else if (hour == 12) {
      return '12:${minute.toString().padLeft(2, '0')} PM';
    } else {
      return '${hour - 12}:${minute.toString().padLeft(2, '0')} PM';
    }
  }

  /// Format timezone offset as "+05:30" or "-05:00"
  String _formatTimezoneOffset(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes.remainder(60).abs();
    final sign = totalMinutes >= 0 ? '+' : '-';
    return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // Helper method to parse TimeOfDay from string
  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      // Handle formats like "09:00 AM", "9:00 AM", "21:00", etc.
      final RegExp regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
        caseSensitive: false,
      );
      final match = regex.firstMatch(timeString);

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {}

    return const TimeOfDay(hour: 9, minute: 0);
  }

  Future<List<Attendee>> getSuggestedAttendees({String? query}) async {
    if (!_isOnline) return [];
    try {
      final response = await meeting.getSuggestedAttendees(query: query);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['attendees'] is List) {
           return (data['attendees'] as List).map((e) => Attendee.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print("MeetingProvider: Error fetching suggestions: $e");
      return [];
    }
  }
}
