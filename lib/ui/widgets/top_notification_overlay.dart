import 'package:flutter/material.dart';
import 'dart:async';

class TopNotificationOverlay extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onPlay;
  final VoidCallback onDismiss;

  const TopNotificationOverlay({
    Key? key,
    required this.title,
    required this.body,
    this.onPlay,
    required this.onDismiss,
  }) : super(key: key);

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
  OverlayEntry? entry;
  
  void removeOverlay() {
    entry?.remove();
    entry = null;
  }

  entry = OverlayEntry(
    builder: (context) => TopNotificationOverlay(
      title: title,
      body: body,
      onPlay: onPlay,
      onDismiss: removeOverlay,
    ),
  );

  Overlay.of(context).insert(entry!);
}
