import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/notification_provider.dart';

class SideMenuButton extends StatelessWidget {
  final bool isTablet;

  const SideMenuButton({
    super.key,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          Scaffold.of(context).openDrawer();
        },
        child: Container(
          padding: EdgeInsets.all(isTablet ? 12 : 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.menu_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                size: isTablet ? 24 : 20,
              ),
              Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  final count = provider.notifications.where((n) => !n.isRead).length;
                  if (count == 0) return const SizedBox.shrink();
                  
                  return Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.canvasColor, // Use canvas to match likely background or transparent
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 10,
                        minHeight: 10,
                      ),
                      child: Text(
                         count > 9 ? '9+' : count.toString(), // Small badge
                         style: const TextStyle(
                           fontSize: 8,
                           color: Colors.white, 
                           fontWeight: FontWeight.bold
                         ),
                         textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
