import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import '../../../models/meeting.dart';
import '../../../models/meetingtype.dart';

class CalendarPage extends StatefulWidget {
  // Accept data from navigation
  final Map<String, dynamic>? data;
  const CalendarPage({super.key, this.data});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime _selectedDate = DateTime.now();
  bool _showingCalendarView = false;

  // Make the meetings list mutable
  final List<Meeting> _todayMeetings = [
    Meeting(
      title: "Board Meeting",
      time: "09:00 AM",
      duration: "2h",
      attendees: ["Sarah", "Marcus", "Lisa", "+3"],
      type: MeetingType.boardMeeting,
    ),
    Meeting(
      title: "Client Presentation",
      time: "11:30 AM",
      duration: "1h 30m",
      attendees: ["Emma", "David"],
      type: MeetingType.client,
    ),
    Meeting(
      title: "Team Sync",
      time: "02:00 PM",
      duration: "45m",
      attendees: ["Engineering Team"],
      type: MeetingType.internal,
    ),
    Meeting(
      title: "Strategy Review",
      time: "04:00 PM",
      duration: "1h",
      attendees: ["Executive Team"],
      type: MeetingType.strategy,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();

    // Handle data returned from AddScheduleScreen
    _handleReturnedData();
  }

  void _handleReturnedData() {
    if (widget.data != null) {
      final action = widget.data!['action'] as String?;
      final meeting = widget.data!['meeting'] as Meeting?;
      final originalMeeting = widget.data!['originalMeeting'] as Meeting?;

      if (action == 'add' && meeting != null) {
        _addNewMeeting(meeting);
      } else if (action == 'update' &&
          meeting != null &&
          originalMeeting != null) {
        _updateMeeting(originalMeeting, meeting);
      }
    }
  }

  void _addNewMeeting(Meeting meeting) {
    setState(() {
      _todayMeetings.add(meeting);
    });

    // Show success message
    _showSuccessMessage('Meeting added successfully!');
  }

  void _updateMeeting(Meeting originalMeeting, Meeting updatedMeeting) {
    setState(() {
      final index = _todayMeetings.indexWhere(
        (m) =>
            m.title == originalMeeting.title && m.time == originalMeeting.time,
      );

      if (index != -1) {
        _todayMeetings[index] = updatedMeeting;
      }
    });

    // Show success message
    _showSuccessMessage('Meeting updated successfully!');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleCalendarView() {
    setState(() {
      _showingCalendarView = !_showingCalendarView;
    });
    HapticFeedback.lightImpact();
  }

  void _selectDateFromCalendar(DateTime date) {
    setState(() {
      _selectedDate = date;
      _showingCalendarView = false;
    });
    HapticFeedback.mediumImpact();
  }

  void _editMeeting(Meeting meeting) {
    HapticFeedback.mediumImpact();
    // Navigate to edit meeting screen with the meeting data
    context.goNamed(
      'addSchedule',
      extra: meeting,
    ); // Pass the Meeting object directly
  }

  void _deleteMeeting(Meeting meeting) {
    HapticFeedback.mediumImpact();
    setState(() {
      _todayMeetings.remove(meeting);
    });

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meeting "${meeting.title}" deleted'),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _todayMeetings.add(meeting);
            });
          },
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(Meeting meeting) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Delete Meeting',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  'Are you sure you want to delete "${meeting.title}"?',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const SideMenu(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withValues(alpha: 0.3),
              theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child:
                      _showingCalendarView
                          ? _buildCalendarView(theme, isTablet, isLargeScreen)
                          : _buildScheduleView(theme, isTablet, isLargeScreen),
                ),
              ),
            ),
            const DraggableMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleView(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        key: const ValueKey('schedule'),
        children: [
          _buildCalendarHeader(theme, isTablet, isLargeScreen),
          _buildDateSelector(theme, isTablet, isLargeScreen),
          _buildTodayOverview(theme, isTablet, isLargeScreen),
          Expanded(child: _buildMeetingsList(theme, isTablet, isLargeScreen)),
        ],
      ),
    );
  }

  Widget _buildCalendarView(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Column(
      key: const ValueKey('calendar'),
      children: [
        _buildCalendarViewHeader(theme, isTablet, isLargeScreen),
        Expanded(child: _buildMonthCalendar(theme, isTablet, isLargeScreen)),
      ],
    );
  }

  Widget _buildCalendarHeader(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final padding =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize:
                        isLargeScreen
                            ? 32
                            : isTablet
                            ? 28
                            : 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 4),
                Text(
                  'Today, ${_formatDate(_selectedDate)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize:
                        isLargeScreen
                            ? 18
                            : isTablet
                            ? 16
                            : 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildHeaderButton(
                Icons.calendar_month_rounded,
                _toggleCalendarView,
                theme,
                isTablet,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              _buildHeaderButton(
                Icons.add_rounded,
                () => context.goNamed('addSchedule'),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: isTablet ? 48 : 40,
          height: isTablet ? 48 : 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: isTablet ? 22 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarViewHeader(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final padding =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _toggleCalendarView,
              child: Container(
                width: isTablet ? 48 : 40,
                height: isTablet ? 48 : 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: theme.colorScheme.onSurface,
                  size: isTablet ? 20 : 16,
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Text(
              'Select Date',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize:
                    isLargeScreen
                        ? 28
                        : isTablet
                        ? 24
                        : 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final margin =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0;
    final padding =
        isLargeScreen
            ? 24.0
            : isTablet
            ? 20.0
            : 16.0;

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalendarMonthHeader(theme, isTablet),
          SizedBox(height: isTablet ? 24 : 20),
          _buildCalendarDaysHeader(theme, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          Expanded(child: _buildCalendarGrid(theme, isTablet)),
        ],
      ),
    );
  }

  Widget _buildCalendarMonthHeader(ThemeData theme, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatFullDate(_selectedDate),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            _buildCalendarNavButton(
              Icons.chevron_left_rounded,
              () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month - 1,
                  );
                });
              },
              theme,
              isTablet,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            _buildCalendarNavButton(
              Icons.chevron_right_rounded,
              () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month + 1,
                  );
                });
              },
              theme,
              isTablet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarNavButton(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isTablet,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: isTablet ? 40 : 32,
          height: isTablet ? 40 : 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: isTablet ? 20 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarDaysHeader(ThemeData theme, bool isTablet) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children:
          days
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, bool isTablet) {
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42, // 6 weeks
      itemBuilder: (context, index) {
        if (index < startingWeekday) {
          return Container(); // Empty cells before month starts
        }

        final day = index - startingWeekday + 1;
        if (day > daysInMonth) {
          return Container(); // Empty cells after month ends
        }

        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _isSameDay(date, _selectedDate);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              _selectDateFromCalendar(date);
            },
            child: Container(
              margin: EdgeInsets.all(isTablet ? 4 : 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : (isToday
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border:
                    isToday && !isSelected
                        ? Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                          width: 1,
                        )
                        : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isSelected
                            ? Colors.white
                            : (isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface),
                    fontSize: isTablet ? 16 : 14,
                    fontWeight:
                        isSelected || isToday
                            ? FontWeight.w600
                            : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final height = isTablet ? 70.0 : 60.0; // Reduced height
    final margin =
        isLargeScreen
            ? 24.0
            : isTablet
            ? 20.0
            : 16.0; // Reduced margin

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index - 1));
          bool isSelected = _isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDate = date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isTablet ? 50 : 45, // Reduced width
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 4 : 3,
              ), // Reduced margin
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(
                  isTablet ? 16 : 14,
                ), // Reduced border radius
                border: Border.all(
                  color:
                      isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 6, // Reduced blur
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDayName(date),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                      fontSize: isTablet ? 11 : 10, // Reduced font size
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: isTablet ? 6 : 5), // Reduced spacing
                  Text(
                    date.day.toString(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                      fontSize: isTablet ? 16 : 14, // Reduced font size
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayOverview(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final margin =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0;
    final padding =
        isLargeScreen
            ? 24.0
            : isTablet
            ? 20.0
            : 16.0;

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          isLargeScreen
              ? Row(
                children: [
                  Expanded(
                    child: _buildOverviewItem(
                      "Meetings",
                      "${_todayMeetings.length}",
                      Icons.event_rounded,
                      theme,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildOverviewItem(
                      "Hours",
                      "5h 15m",
                      Icons.schedule_rounded,
                      theme,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildOverviewItem(
                      "Free Time",
                      "2h 45m",
                      Icons.free_breakfast_rounded,
                      theme,
                      isTablet,
                    ),
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOverviewItem(
                    "Meetings",
                    "${_todayMeetings.length}",
                    Icons.event_rounded,
                    theme,
                    isTablet,
                  ),
                  _buildOverviewItem(
                    "Hours",
                    "5h 15m",
                    Icons.schedule_rounded,
                    theme,
                    isTablet,
                  ),
                  _buildOverviewItem(
                    "Free Time",
                    "2h 45m",
                    Icons.free_breakfast_rounded,
                    theme,
                    isTablet,
                  ),
                ],
              ),
    );
  }

  Widget _buildOverviewItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
    bool isTablet,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 12 : 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: isTablet ? 24 : 20,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isTablet ? 6 : 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: isTablet ? 13 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingsList(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final padding =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: ListView.builder(
        itemCount: _todayMeetings.length,
        itemBuilder: (context, index) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.3, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Interval(
                  0.1 + (index * 0.1),
                  0.5 + (index * 0.1),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _fadeController,
                  curve: Interval(
                    0.2 + (index * 0.1),
                    0.6 + (index * 0.1),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: _buildMeetingItem(
                _todayMeetings[index],
                index,
                theme,
                isTablet,
                isLargeScreen,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingItem(
    Meeting meeting,
    int index,
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    Color accentColor = _getMeetingColor(meeting.type, theme);

    return Dismissible(
      key: Key(meeting.title + meeting.time),
      background: _buildSwipeBackground(isEdit: true, isTablet: isTablet),
      secondaryBackground: _buildSwipeBackground(
        isEdit: false,
        isTablet: isTablet,
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _editMeeting(meeting);
        } else {
          _deleteMeeting(meeting);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit action - don't dismiss, just trigger edit
          _editMeeting(meeting);
          return false;
        } else {
          // Delete action - show confirmation
          return await _showDeleteConfirmation(meeting);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
        padding: EdgeInsets.all(
          isLargeScreen
              ? 24.0
              : isTablet
              ? 20.0
              : 16.0,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 6 : 4,
              height: isTablet ? 70 : 60,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(isTablet ? 3 : 2),
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meeting.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize:
                                isLargeScreen
                                    ? 18
                                    : isTablet
                                    ? 16
                                    : 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 12 : 8,
                          vertical: isTablet ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 12 : 8,
                          ),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          meeting.duration,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accentColor,
                            fontSize: isTablet ? 12 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        size: isTablet ? 18 : 16,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        meeting.time,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                          fontSize: isTablet ? 14 : 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        size: isTablet ? 18 : 16,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Expanded(
                        child: Text(
                          meeting.attendees.join(', '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: isTablet ? 13 : 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({required bool isEdit, required bool isTablet}) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color:
            isEdit
                ? Colors.blue.withValues(alpha: 0.8)
                : Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      ),
      child: Align(
        alignment: isEdit ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEdit ? Icons.edit_rounded : Icons.delete_rounded,
                color: Colors.white,
                size: isTablet ? 28 : 24,
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Text(
                isEdit ? 'Edit' : 'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMeetingColor(MeetingType type, ThemeData theme) {
    switch (type) {
      case MeetingType.boardMeeting:
        return theme.colorScheme.primary;
      case MeetingType.client:
        return Colors.blue;
      case MeetingType.internal:
        return Colors.green;
      case MeetingType.strategy:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatFullDate(DateTime date) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDayName(DateTime date) {
    List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
