import 'package:flutter/material.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/providers/meeting_provider.dart';
import 'package:provider/provider.dart';

class FirebaseSyncService {
  final String userId;

  FirebaseSyncService({required this.userId});

  Future<void> syncTasks(TaskProvider taskProvider) async {
    await taskProvider.syncUnsyncedTasks();
  }

  Future<void> syncMeetings(MeetingProvider meetingProvider) async {}

  Future<void> fullSync(TaskProvider taskProvider, MeetingProvider meetingProvider) async {
    await taskProvider.onConnectivityChanged();
    await meetingProvider.onConnectivityChanged();
  }
}
