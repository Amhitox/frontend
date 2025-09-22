import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/task_provider.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        Color statusColor;
        IconData statusIcon;
        String statusText;
        if (taskProvider.isSyncing) {
          statusColor = Colors.blue;
          statusIcon = Icons.sync;
          statusText = 'Syncing...';
        } else if (taskProvider.isOnline) {
          statusColor = Colors.green;
          statusIcon = Icons.cloud_done;
          statusText = 'Online';
        } else {
          statusColor = Colors.orange;
          statusIcon = Icons.cloud_off;
          statusText = 'Offline';
        }
        return GestureDetector(
          onTap: () {
            if (!taskProvider.isSyncing) {
              print('Manual sync triggered from UI');
              taskProvider.forceSync();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (taskProvider.isSyncing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  )
                else
                  Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
