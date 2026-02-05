import 'package:flutter/material.dart';
import 'dart:async';

class TopNotificationOverlay extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onPlay;
  final VoidCallback onDismiss;

  const TopNotificationOverlay({
    super.key,
    required this.title,
    required this.body,
    this.onPlay,
    required this.onDismiss,
  });

  @override
  State<TopNotificationOverlay> createState() => _TopNotificationOverlayState();
}

class _TopNotificationOverlayState extends State<TopNotificationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after 6 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 6), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: SlideTransition(
            position: _offsetAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Dismissible(
                key: ValueKey('top_notification'),
                direction: DismissDirection.up,
                onDismissed: (_) {
                  widget.onDismiss();
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                         theme.colorScheme.surfaceContainerHighest,
                         theme.colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.priority_high_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Action Button
                        if (widget.onPlay != null) ...[
                          const SizedBox(width: 8),
                          Container(
                             decoration: BoxDecoration(
                               color: theme.colorScheme.primary,
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: IconButton(
                               icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                               onPressed: () {
                                 _dismiss();
                                 widget.onPlay!();
                               },
                             ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Global helper to show
void showTopNotification({
  required BuildContext context,
  required String title,
  required String body,
  VoidCallback? onPlay,
}) {
  // Use showDialog which creates its own overlay and works with any valid context
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    useSafeArea: false,
    builder: (dialogContext) {
      return _TopNotificationDialog(
        title: title,
        body: body,
        onPlay: onPlay,
      );
    },
  );
}

class _TopNotificationDialog extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onPlay;

  const _TopNotificationDialog({
    required this.title,
    required this.body,
    this.onPlay,
  });

  @override
  State<_TopNotificationDialog> createState() => _TopNotificationDialogState();
}

class _TopNotificationDialogState extends State<_TopNotificationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // Transparent barrier to allow tapping anywhere to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // The notification card at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: SlideTransition(
              position: _offsetAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Dismissible(
                  key: const ValueKey('top_notification'),
                  direction: DismissDirection.up,
                  onDismissed: (_) {
                    Navigator.of(context).pop();
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                             theme.colorScheme.surfaceContainerHighest,
                             theme.colorScheme.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.priority_high_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.body,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action Button
                            if (widget.onPlay != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                 decoration: BoxDecoration(
                                   color: theme.colorScheme.primary,
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 child: IconButton(
                                   icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                                   onPressed: () {
                                     Navigator.of(context).pop();
                                     widget.onPlay!();
                                   },
                                 ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
