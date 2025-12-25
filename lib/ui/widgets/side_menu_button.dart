import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          child: Icon(
            Icons.menu_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            size: isTablet ? 24 : 20,
          ),
        ),
      ),
    );
  }
}
