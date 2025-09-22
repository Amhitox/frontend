import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/services/firabasesync_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/providers/meeting_provider.dart';

class ConnectivityService {
  final FirebaseSyncService syncService;
  final VoidCallback? onConnectivityRestored;
  BuildContext? _context;
  ConnectivityService({
    required this.syncService,
    this.onConnectivityRestored,
  }) {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline = results.any(
        (result) => result != ConnectivityResult.none,
      );
      print('ConnectivityService: Connectivity changed - Online: $isOnline');
      if (isOnline) {
        print('ConnectivityService: Triggering sync');
        onConnectivityRestored?.call();
        _syncTasksIfContextAvailable();
      }
    });
  }
  void setContext(BuildContext context) {
    _context = context;
  }

  void _syncTasksIfContextAvailable() {
    if (_context != null) {
      print('ConnectivityService: Syncing providers');
      try {
        final taskProvider = Provider.of<TaskProvider>(
          _context!,
          listen: false,
        );
        print(
          'ConnectivityService: Calling TaskProvider.onConnectivityChanged()',
        );
        taskProvider.onConnectivityChanged();
      } catch (e) {
        print('ConnectivityService: Error accessing TaskProvider: $e');
        syncService.fullSync(_context!);
      }
      try {
        final meetingProvider = Provider.of<MeetingProvider>(
          _context!,
          listen: false,
        );
        print(
          'ConnectivityService: Calling MeetingProvider.onConnectivityChanged()',
        );
        meetingProvider.onConnectivityChanged();
      } catch (e) {
        print('ConnectivityService: Error accessing MeetingProvider: $e');
      }
    } else {
      print('ConnectivityService: No context available for sync');
    }
  }
}
