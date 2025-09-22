import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/task_provider.dart';
class AnimatedSyncButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ThemeData theme;
  final bool isTablet;
  const AnimatedSyncButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.onLongPress,
    required this.theme,
    required this.isTablet,
  });
  @override
  State<AnimatedSyncButton> createState() => _AnimatedSyncButtonState();
}
class _AnimatedSyncButtonState extends State<AnimatedSyncButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isSyncing) {
          _animationController.repeat();
        } else {
          _animationController.stop();
        }
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: taskProvider.isSyncing ? null : widget.onTap,
            onLongPress: widget.onLongPress,
            child: Container(
              width: widget.isTablet ? 48 : 40,
              height: widget.isTablet ? 48 : 40,
              decoration: BoxDecoration(
                color:
                    taskProvider.isSyncing
                        ? widget.theme.colorScheme.primary.withValues(
                          alpha: 0.2,
                        )
                        : widget.theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      taskProvider.isSyncing
                          ? widget.theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          )
                          : widget.theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                  width: 1,
                ),
              ),
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Icon(
                      widget.icon,
                      color:
                          taskProvider.isSyncing
                              ? widget.theme.colorScheme.primary
                              : widget.theme.colorScheme.primary,
                      size: widget.isTablet ? 22 : 18,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
