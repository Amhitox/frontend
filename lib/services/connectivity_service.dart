import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/services/firabasesync_service.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final FirebaseSyncService syncService;
  final VoidCallback? onConnectivityRestored;
  
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
        print('ConnectivityService: Triggering custom restore callback');
        onConnectivityRestored?.call();
      }
    });
  }

  // Deprecated context usage that caused crashes
  void setContext(BuildContext context) {}
}
