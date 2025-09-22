import 'package:flutter/material.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:provider/provider.dart';

class FirebaseSyncService {
  final String userId;

  FirebaseSyncService({required this.userId});

  Future<void> syncTasks(BuildContext context) async {
    final taskProvider = context.read<TaskProvider>();
    await taskProvider.syncUnsyncedTasks();
  }

  Future<void> syncMeetings(BuildContext context) async {}

  Future<void> fullSync(BuildContext context) async {
    final taskProvider = context.read<TaskProvider>();
    await taskProvider.onConnectivityChanged();
  }
}
