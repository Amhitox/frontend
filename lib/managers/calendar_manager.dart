import 'package:flutter/foundation.dart';
import 'package:frontend/models/meeting.dart';
import 'package:hive_flutter/hive_flutter.dart';
class CalendarManager {
  static final CalendarManager _instance = CalendarManager._internal();
  factory CalendarManager() => _instance;
  CalendarManager._internal();
  Box<Meeting>? _box;
  Box<String>? _syncBox;
  Box<String>? _deletedBox;
  Future<void> init(String userId) async {
    _box = await Hive.openBox<Meeting>('meetings_$userId');
    _syncBox = await Hive.openBox<String>('sync_status_$userId');
    _deletedBox = await Hive.openBox<String>('deleted_meetings_$userId');
  }
  bool get isInitialized =>
      _box != null && _syncBox != null && _deletedBox != null;
  Future<void> addOrUpdateMeeting(
    Meeting meeting, {
    bool isSynced = false,
  }) async {
    if (!isInitialized) {
      throw Exception('CalendarManager not initialized. Call init() first.');
    }
    await _box!.put(meeting.id, meeting);
    await _syncBox!.put('${meeting.id}_synced', isSynced.toString());
  }
  Future<void> markMeetingAsSynced(String meetingId) async {
    if (!isInitialized) return;
    await _syncBox!.put('${meetingId}_synced', 'true');
  }
  List<Meeting> getMeetingOfDate(DateTime date) {
    if (!isInitialized) {
      return [];
    }
    final dateStr = date.toIso8601String().split('T').first;
    return _box!.values
        .where((t) {
          if (t.date == null || t.date!.isEmpty) return false;
          // Normalize the stored date for comparison
          final storedDate = t.date!.contains('T') 
              ? t.date!.split('T').first.trim()
              : t.date!.trim();
          return storedDate == dateStr;
        })
        .toList();
  }
  ValueListenable<Box<Meeting>>? listenable() {
    if (!isInitialized) {
      return null;
    }
    return _box!.listenable();
  }
  List<Meeting> getAllUnsyncedMeetings() {
    if (!isInitialized) {
      return [];
    }
    return _box!.values.where((meeting) {
      final syncStatus = _syncBox!.get('${meeting.id}_synced');
      return syncStatus != 'true';
    }).toList();
  }
  List<Meeting> getAllMeetings() {
    if (!isInitialized) {
      return [];
    }
    return _box!.values.toList();
  }
  Meeting? getMeetingById(String id) {
    if (!isInitialized) {
      return null;
    }
    return _box!.get(id);
  }
  bool isMeetingSynced(String meetingId) {
    if (!isInitialized) return false;
    final syncStatus = _syncBox!.get('${meetingId}_synced');
    return syncStatus == 'true';
  }
  Future<void> deleteMeeting(String id) async {
    if (!isInitialized) {
      throw Exception('CalendarManager not initialized. Call init() first.');
    }
    final wasSynced = _syncBox!.get('${id}_synced') == 'true';
    if (wasSynced) {
      await _deletedBox!.put('deleted_$id', id);
    }
    await _box!.delete(id);
    await _syncBox!.delete('${id}_synced');
  }
  List<String> getDeletedMeetings() {
    if (!isInitialized) {
      return [];
    }
    return _deletedBox!.values.toList();
  }
  Future<void> clearDeletedMeeting(String meetingId) async {
    if (!isInitialized) return;
    await _deletedBox!.delete('deleted_$meetingId');
  }
  Future<void> clearAllMeetings() async {
    if (!isInitialized) {
      throw Exception('CalendarManager not initialized. Call init() first.');
    }
    await _box!.clear();
    await _syncBox!.clear();
    await _deletedBox!.clear();
  }
  Future<void> syncMeetingsFromServer(List<Meeting> serverMeetings) async {
    if (!isInitialized) return;
    for (final meeting in serverMeetings) {
      await addOrUpdateMeeting(meeting, isSynced: true);
    }
  }
  Future<void> updateMeetingFromServer(Meeting meeting) async {
    if (!isInitialized) return;
    await addOrUpdateMeeting(meeting, isSynced: true);
  }

  Future<void> logout() async {
    if (_box != null && _box!.isOpen) await _box!.close();
    if (_syncBox != null && _syncBox!.isOpen) await _syncBox!.close();
    if (_deletedBox != null && _deletedBox!.isOpen) await _deletedBox!.close();
    
    _box = null;
    _syncBox = null;
    _deletedBox = null;
  }
}
