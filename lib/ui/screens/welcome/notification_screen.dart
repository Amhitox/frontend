import 'package:flutter/material.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}
class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unread', 'Today', 'This Week'];
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'New Email from Sarah Chen',
      message:
          'Q4 Strategic Review Meeting - The board meeting has been scheduled...',
      time: '2m ago',
      type: NotificationType.email,
      isRead: false,
      priority: NotificationPriority.high,
    ),
    NotificationItem(
      id: '2',
      title: 'Task Completed',
      message:
          'Budget Analysis Report has been completed and is ready for review.',
      time: '5m ago',
      type: NotificationType.task,
      isRead: false,
      priority: NotificationPriority.normal,
    ),
    NotificationItem(
      id: '3',
      title: 'Meeting Reminder',
      message:
          'Team standup meeting starts in 15 minutes in Conference Room A.',
      time: '15m ago',
      type: NotificationType.meeting,
      isRead: true,
      priority: NotificationPriority.high,
    ),
    NotificationItem(
      id: '4',
      title: 'System Update Available',
      message:
          'A new version of the app is available. Update now to get the latest features.',
      time: '1h ago',
      type: NotificationType.system,
      isRead: false,
      priority: NotificationPriority.low,
    ),
    NotificationItem(
      id: '5',
      title: 'Weekly Report Generated',
      message: 'Your productivity report for this week is ready to view.',
      time: '2h ago',
      type: NotificationType.report,
      isRead: true,
      priority: NotificationPriority.normal,
    ),
    NotificationItem(
      id: '6',
      title: 'Security Alert',
      message:
          'Unusual login activity detected from a new device. Please verify.',
      time: '3h ago',
      type: NotificationType.security,
      isRead: false,
      priority: NotificationPriority.high,
    ),
    NotificationItem(
      id: '7',
      title: 'Calendar Event Added',
      message:
          'New event "Client Presentation" added to your calendar for tomorrow.',
      time: '5h ago',
      type: NotificationType.calendar,
      isRead: true,
      priority: NotificationPriority.normal,
    ),
    NotificationItem(
      id: '8',
      title: 'Backup Completed',
      message: 'Your data has been successfully backed up to cloud storage.',
      time: 'Yesterday',
      type: NotificationType.system,
      isRead: true,
      priority: NotificationPriority.low,
    ),
  ];
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
  List<NotificationItem> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Unread':
        return _notifications
            .where((notification) => !notification.isRead)
            .toList();
      case 'Today':
        return _notifications
            .where(
              (notification) =>
                  notification.time.contains('m ago') ||
                  notification.time.contains('h ago'),
            )
            .toList();
      case 'This Week':
        return _notifications
            .where((notification) => !notification.time.contains('Yesterday'))
            .toList();
      default:
        return _notifications;
    }
  }
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const SideMenu(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withValues(alpha: 0.1),
              theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(isTablet, theme),
                    _buildFilterTabs(isTablet, theme),
                    _buildQuickStats(isTablet, theme),
                    Expanded(child: _buildNotificationsList(isTablet, theme)),
                  ],
                ),
              ),
            ),
            const DraggableMenu(),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(bool isTablet, ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 20 : 16),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.1),
            theme.colorScheme.surface.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 52 : 48,
            height: isTablet ? 52 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.withValues(alpha: 0.4),
                  Colors.red.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: theme.colorScheme.onSurface,
              size: isTablet ? 26 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: isTablet ? 24 : 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: isTablet ? 4 : 2),
                Text(
                  '${_filteredNotifications.length} notifications',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildHeaderButton(
                Icons.done_all,
                () => _markAllAsRead(theme, isTablet),
                theme,
                isTablet,
              ),
              SizedBox(width: isTablet ? 10 : 8),
              _buildHeaderButton(
                Icons.clear_all,
                () => _clearAllNotifications(theme, isTablet),
                theme,
                isTablet,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildHeaderButton(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isTablet ? 40 : 36,
        height: isTablet ? 40 : 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.onSurface,
          size: isTablet ? 18 : 16,
        ),
      ),
    );
  }
  Widget _buildFilterTabs(bool isTablet, ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 12 : 8,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children:
            _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 10 : 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.colorScheme.secondary.withValues(
                                alpha: 0.1,
                              )
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          fontSize: isTablet ? 13 : 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
  Widget _buildQuickStats(bool isTablet, ThemeData theme) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final highPriorityCount =
        _notifications
            .where((n) => n.priority == NotificationPriority.high)
            .length;
    final todayCount =
        _notifications
            .where((n) => n.time.contains('m ago') || n.time.contains('h ago'))
            .length;
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 20 : 16,
        8,
        isTablet ? 20 : 16,
        isTablet ? 20 : 16,
      ),
      child: Row(
        children: [
          _buildStatChip(
            '$unreadCount',
            'Unread',
            Colors.blue,
            theme,
            isTablet,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          _buildStatChip(
            '$highPriorityCount',
            'Priority',
            Colors.red,
            theme,
            isTablet,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          _buildStatChip('$todayCount', 'Today', Colors.green, theme, isTablet),
        ],
      ),
    );
  }
  Widget _buildStatChip(
    String count,
    String label,
    Color color,
    ThemeData theme,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isTablet ? 7 : 6,
            height: isTablet ? 7 : 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: isTablet ? 8 : 6),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: isTablet ? 13 : 12,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNotificationsList(bool isTablet, ThemeData theme) {
    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState(isTablet, theme);
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildNotificationItem(
                  _filteredNotifications[index],
                  isTablet,
                  theme,
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildNotificationItem(
    NotificationItem notification,
    bool isTablet,
    ThemeData theme,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _dismissNotification(notification),
      background: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete, color: Colors.red, size: isTablet ? 26 : 24),
      ),
      child: GestureDetector(
        onTap: () => _markAsRead(notification),
        child: Container(
          margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: notification.isRead ? 0.03 : 0.08,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            border: Border.all(
              color:
                  notification.priority == NotificationPriority.high
                      ? Colors.red.withValues(alpha: 0.4)
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(
                notification.type,
                notification.priority,
                isTablet,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: isTablet ? 16 : 15,
                              fontWeight:
                                  notification.isRead
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: isTablet ? 14 : 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Row(
                      children: [
                        Text(
                          notification.time,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: isTablet ? 13 : 12,
                          ),
                        ),
                        const Spacer(),
                        _buildPriorityBadge(notification.priority, isTablet),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildNotificationIcon(
    NotificationType type,
    NotificationPriority priority,
    bool isTablet,
  ) {
    IconData icon;
    Color color;
    switch (type) {
      case NotificationType.email:
        icon = Icons.email_outlined;
        color = Colors.blue;
        break;
      case NotificationType.task:
        icon = Icons.task_alt_outlined;
        color = Colors.green;
        break;
      case NotificationType.meeting:
        icon = Icons.event_outlined;
        color = Colors.orange;
        break;
      case NotificationType.system:
        icon = Icons.system_update_outlined;
        color = Colors.purple;
        break;
      case NotificationType.security:
        icon = Icons.security_outlined;
        color = Colors.red;
        break;
      case NotificationType.report:
        icon = Icons.analytics_outlined;
        color = Colors.teal;
        break;
      case NotificationType.calendar:
        icon = Icons.calendar_today_outlined;
        color = Colors.indigo;
        break;
    }
    return Container(
      width: isTablet ? 44 : 40,
      height: isTablet ? 44 : 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
      ),
      child: Icon(icon, color: color, size: isTablet ? 22 : 20),
    );
  }
  Widget _buildPriorityBadge(NotificationPriority priority, bool isTablet) {
    if (priority == NotificationPriority.normal) return const SizedBox();
    Color color;
    String text;
    switch (priority) {
      case NotificationPriority.high:
        color = Colors.red;
        text = 'High';
        break;
      case NotificationPriority.low:
        color = Colors.grey;
        text = 'Low';
        break;
      default:
        return const SizedBox();
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: isTablet ? 11 : 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  Widget _buildEmptyState(bool isTablet, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isTablet ? 90 : 80,
            height: isTablet ? 90 : 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            ),
            child: Icon(
              Icons.notifications_none,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: isTablet ? 45 : 40,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'No Notifications',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You're all caught up!",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: isTablet ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }
  void _markAllAsRead(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            ),
            title: Text(
              'Mark All as Read',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 20 : 18,
              ),
            ),
            content: Text(
              'Are you sure you want to mark all notifications as read?',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    for (var notification in _notifications) {
                      notification.isRead = true;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  'Mark All as Read',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }
  void _clearAllNotifications(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            ),
            title: Text(
              'Clear All Notifications',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 20 : 18,
              ),
            ),
            content: Text(
              'Are you sure you want to clear all notifications? This action cannot be undone.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() => _notifications.clear());
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }
  void _markAsRead(NotificationItem notification) {
    setState(() => notification.isRead = true);
  }
  void _dismissNotification(NotificationItem notification) {
    setState(() => _notifications.removeWhere((n) => n.id == notification.id));
  }
}
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  bool isRead;
  final NotificationPriority priority;
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
    required this.priority,
  });
}
enum NotificationType {
  email,
  task,
  meeting,
  system,
  security,
  report,
  calendar,
}
enum NotificationPriority { high, normal, low }
