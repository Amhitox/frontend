import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/meeting_provider.dart';

class MeetingSyncStatusIndicator extends StatelessWidget {
  const MeetingSyncStatusIndicator({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<MeetingProvider>(
      builder: (context, meetingProvider, child) {
        Color statusColor;
        IconData statusIcon;
        String statusText;
        if (meetingProvider.isSyncing) {
          statusColor = Colors.blue;
          statusIcon = Icons.sync;
          statusText = 'Syncing...';
        } else if (meetingProvider.isOnline) {
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
            if (!meetingProvider.isSyncing) {
              print('Manual meeting sync triggered from UI');
              meetingProvider.forceSync();
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
                if (meetingProvider.isSyncing)
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
