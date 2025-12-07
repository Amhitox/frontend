import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/meeting_location.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:frontend/ui/widgets/calendar_view.dart';
import 'package:frontend/ui/widgets/meeting_sync_status_indicator.dart';
import 'package:frontend/providers/meeting_provider.dart';
import 'package:provider/provider.dart';
import '../../../models/meeting.dart';

class CalendarPage extends StatefulWidget {
  final Map<String, dynamic>? data;
  final List<Meeting> meetings;
  final DateTime date;
  const CalendarPage({
    super.key,
    this.data,
    this.meetings = const [],
    required this.date,
  });
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentWeekStart = DateTime.now();
  bool _showingCalendarView = false;
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
    _pageController = PageController(initialPage: 1000);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideController.forward();
    _fadeController.forward();
    _selectedDate = widget.date;
    _currentWeekStart = _getWeekStart(_selectedDate);
    _handleReturnedData();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
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

  void _addNewMeeting(Meeting meeting) async {
    try {
      final meetingProvider = context.read<MeetingProvider>();
      final meetingDate = DateTime.parse(
        meeting.date ?? DateTime.now().toIso8601String().split('T').first,
      );
      final startTime = _parseTimeOfDay(meeting.startTime ?? '09:00 AM');
      final endTime = _parseTimeOfDay(meeting.endTime ?? '10:00 AM');
      await meetingProvider.addMeeting(
        meeting.title ?? '',
        meeting.description ?? '',
        meetingDate,
        startTime,
        endTime,
        meeting.attendees ?? [],
        meeting.location ?? MeetingLocation.online,
      );
      _showSuccessMessage('Meeting added successfully!');
    } catch (e) {
      _showErrorMessage('Failed to add meeting: $e');
    }
  }

  void _updateMeeting(Meeting originalMeeting, Meeting updatedMeeting) async {
    try {
      final meetingProvider = context.read<MeetingProvider>();
      await meetingProvider.updateMeeting(
        originalMeeting.id ?? '',
        updatedMeeting.title ?? '',
        updatedMeeting.description ?? '',
        DateTime.parse(
          updatedMeeting.date ??
              DateTime.now().toIso8601String().split('T').first,
        ),
        _parseTimeOfDay(updatedMeeting.startTime ?? '09:00 AM'),
        _parseTimeOfDay(updatedMeeting.endTime ?? '10:00 AM'),
        updatedMeeting.attendees ?? [],
        updatedMeeting.location ?? MeetingLocation.online,
      );
      _showSuccessMessage('Meeting updated successfully!');
    } catch (e) {
      _showErrorMessage('Failed to update meeting: $e');
    }
  }

  void _deleteMeeting(Meeting meeting) async {
    try {
      final meetingProvider = context.read<MeetingProvider>();
      await meetingProvider.deleteMeeting(meeting.id ?? '');
      _showSuccessMessage('Meeting deleted successfully!');
    } catch (e) {
      _showErrorMessage('Failed to delete meeting: $e');
    }
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<Meeting> _getMeetingsForDate(DateTime date) {
    if (_isSameDay(date, widget.date)) {
      return widget.meetings;
    }
    // Use watch instead of read to listen to provider changes
    final meetingProvider = context.watch<MeetingProvider>();
    final dateString = date.toIso8601String().split('T').first;
    return meetingProvider.getMeetings(dateString);
  }

  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _refreshMeetingsForDate(_selectedDate);
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _refreshMeetingsForDate(_selectedDate);
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _currentWeekStart = _getWeekStart(DateTime.now());
    });
    _refreshMeetingsForDate(DateTime.now());
  }

  void _toggleCalendarView() {
    setState(() {
      _showingCalendarView = !_showingCalendarView;
    });
  }

  void _selectDateFromCalendar(DateTime date) {
    setState(() {
      _selectedDate = date;
      _currentWeekStart = _getWeekStart(date);
      _showingCalendarView = false;
    });
    _refreshMeetingsForDate(date);
  }

  void _refreshMeetingsForDate(DateTime date) async {
    final meetingProvider = context.read<MeetingProvider>();
    final dateString = date.toIso8601String().split('T').first;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _showingCalendarView
                        ? _buildCalendarView()
                        : FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            key: const ValueKey('weekView'),
                            children: [
                              _buildCalendarHeader(theme, isTablet),
                              _buildWeekNavigation(theme, isTablet),
                              _buildWeekDaysHeader(theme, isTablet),
                              Expanded(child: _buildWeekView(theme, isTablet)),
                            ],
                          ),
                        ),
              ),
            ),
            const DraggableMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(ThemeData theme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
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
                  'Calendar',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 4),
                Text(
                  _formatMonthYear(_selectedDate),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: isTablet ? 16 : 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const MeetingSyncStatusIndicator(),
              SizedBox(width: isTablet ? 12 : 8),
              _buildHeaderButton(
                Icons.calendar_month_rounded,
                _toggleCalendarView,
                theme,
                isTablet,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              _buildHeaderButton(
                Icons.add_rounded,
                () => context.pushNamed('addSchedule'),
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

  Widget _buildWeekNavigation(ThemeData theme, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 20.0,
        vertical: isTablet ? 12.0 : 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousWeek,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: theme.colorScheme.onSurface,
              size: isTablet ? 28 : 24,
            ),
          ),
          GestureDetector(
            onTap: _goToToday,
            child: Text(
              _getWeekTitle(_currentWeekStart),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: _goToNextWeek,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface,
              size: isTablet ? 28 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader(ThemeData theme, bool isTablet) {
    final weekDays = _getWeekDays(_currentWeekStart);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 20.0),
      height: isTablet ? 70 : 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children:
            weekDays
                .map((day) => _buildWeekDayHeader(day, theme, isTablet))
                .toList(),
      ),
    );
  }

  Widget _buildWeekDayHeader(DateTime day, ThemeData theme, bool isTablet) {
    final isToday = _isSameDay(day, DateTime.now());
    final isSelected = _isSameDay(day, _selectedDate);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = day;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDayName(day),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: isTablet ? 12 : 10,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: isTablet ? 28 : 24,
                height: isTablet ? 28 : 24,
                decoration: BoxDecoration(
                  color:
                      isToday
                          ? theme.colorScheme.primary
                          : isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day.day.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          isToday
                              ? Colors.white
                              : isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView(ThemeData theme, bool isTablet) {
    final meetings = _getMeetingsForDate(_selectedDate);
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _formatDayHeader(_selectedDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${meetings.length} meetings',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Expanded(child: _buildTimeSlots(meetings, theme, isTablet)),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(
    List<Meeting> meetings,
    ThemeData theme,
    bool isTablet,
  ) {
    final timeSlotHeight = isTablet ? 60.0 : 50.0;
    final totalHours = 24;
    final totalHeight = totalHours * timeSlotHeight;
    return SingleChildScrollView(
      controller: ScrollController(
        initialScrollOffset: _getInitialScrollOffset(timeSlotHeight),
      ),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            Column(
              children: List.generate(totalHours, (index) {
                final hour = index;
                return SizedBox(
                  height: timeSlotHeight,
                  child: Row(
                    children: [
                      Container(
                        width: isTablet ? 60 : 50,
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          _formatHour24(hour),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: isTablet ? 12 : 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.only(
                              top: timeSlotHeight / 2 - 0.25,
                            ),
                            height: 0.5,
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            _buildCurrentTimeIndicator(theme, isTablet, timeSlotHeight),
            ..._buildMeetingBlocksWithOverlap(
              meetings,
              theme,
              isTablet,
              timeSlotHeight,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMeetingBlocksWithOverlap(
    List<Meeting> meetings,
    ThemeData theme,
    bool isTablet,
    double timeSlotHeight,
  ) {
    final sortedMeetings = List<Meeting>.from(meetings)..sort(
      (a, b) => _getMeetingTimeInMinutes(
        a.startTime ?? '',
      ).compareTo(_getMeetingTimeInMinutes(b.startTime ?? '')),
    );
    List<Widget> meetingBlocks = [];
    List<Meeting> currentGroup = [];
    for (int i = 0; i < sortedMeetings.length; i++) {
      final meeting = sortedMeetings[i];
      if (currentGroup.isEmpty) {
        currentGroup.add(meeting);
      } else {
        final lastMeeting = currentGroup.last;
        final lastEndTime = _getMeetingTimeInMinutes(lastMeeting.endTime ?? '');
        final currentStartTime = _getMeetingTimeInMinutes(
          meeting.startTime ?? '',
        );
        if (currentStartTime < lastEndTime) {
          currentGroup.add(meeting);
        } else {
          meetingBlocks.addAll(
            _renderMeetingGroup(currentGroup, theme, isTablet, timeSlotHeight),
          );
          currentGroup = [meeting];
        }
      }
    }
    if (currentGroup.isNotEmpty) {
      meetingBlocks.addAll(
        _renderMeetingGroup(currentGroup, theme, isTablet, timeSlotHeight),
      );
    }
    return meetingBlocks;
  }

  List<Widget> _renderMeetingGroup(
    List<Meeting> meetings,
    ThemeData theme,
    bool isTablet,
    double timeSlotHeight,
  ) {
    List<Widget> blocks = [];
    if (meetings.length == 1) {
      blocks.add(
        _buildPositionedMeetingBlock(
          meetings.first,
          theme,
          isTablet,
          timeSlotHeight,
          leftOffset: 0,
          width: 1.0,
        ),
      );
    } else {
      for (int i = 0; i < meetings.length; i++) {
        final meeting = meetings[i];
        final leftOffset = i / meetings.length;
        final width = 1.0 / meetings.length;
        blocks.add(
          _buildPositionedMeetingBlock(
            meeting,
            theme,
            isTablet,
            timeSlotHeight,
            leftOffset: leftOffset,
            width: width,
            index: i,
            totalMeetings: meetings.length,
          ),
        );
      }
    }
    return blocks;
  }

  Widget _buildPositionedMeetingBlock(
    Meeting meeting,
    ThemeData theme,
    bool isTablet,
    double timeSlotHeight, {
    double leftOffset = 0.0,
    double width = 1.0,
    int index = 0,
    int totalMeetings = 1,
  }) {
    final startTime = _getMeetingTimeInMinutes(meeting.startTime ?? '');
    final endTime = _getMeetingTimeInMinutes(meeting.endTime ?? '');
    final duration = endTime - startTime;
    final minutesPerPixel = timeSlotHeight / 60.0;
    final topPosition = (startTime + 30) * minutesPerPixel;
    final blockHeight = duration * minutesPerPixel;
    final baseLeftOffset = isTablet ? 60.0 : 50.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - baseLeftOffset - 24;
    final marginBetweenMeetings = totalMeetings > 1 ? 0.2 : 0.0;
    final totalMarginSpace = (totalMeetings - 1) * marginBetweenMeetings;
    final adjustedAvailableWidth = availableWidth - totalMarginSpace;
    final actualLeftOffset =
        baseLeftOffset +
        (leftOffset * adjustedAvailableWidth) +
        (index * marginBetweenMeetings);
    final actualWidth = (adjustedAvailableWidth * width);
    final maxRightPosition = screenWidth - 12;
    final actualRightPosition = actualLeftOffset + actualWidth;
    final finalWidth =
        actualRightPosition > maxRightPosition
            ? maxRightPosition - actualLeftOffset
            : actualWidth;
    if (totalMeetings > 2) {}
    final accentColor = _getMeetingColor(
      meeting.location ?? MeetingLocation.online,
      theme,
    );
    final showTime = blockHeight >= 30 && totalMeetings <= 2;
    final showAttendees =
        (meeting.attendees?.isNotEmpty ?? false) && totalMeetings <= 2;
    final showLocation = blockHeight >= 35 && totalMeetings <= 2;
    final titleFontSize =
        blockHeight >= 50 ? (isTablet ? 12.0 : 10.0) : (isTablet ? 10.0 : 9.0);
    final timeFontSize =
        blockHeight >= 50 ? (isTablet ? 10.0 : 9.0) : (isTablet ? 9.0 : 8.0);
    final attendeesFontSize =
        blockHeight >= 50 ? (isTablet ? 9.0 : 8.0) : (isTablet ? 8.0 : 7.0);
    final locationFontSize =
        blockHeight >= 50 ? (isTablet ? 8.0 : 7.0) : (isTablet ? 7.0 : 6.0);
    return Positioned(
      top: topPosition,
      left: actualLeftOffset + 12,
      right:
          totalMeetings == 1
              ? 12
              : (screenWidth - (actualLeftOffset + finalWidth + 12)),
      height: blockHeight < 30 ? 30 : blockHeight,
      child: GestureDetector(
        onTap: () => _showMeetingDetails(meeting),
        onLongPress: () => _showDeleteConfirmation(meeting),
        child: Container(
          padding: EdgeInsets.all(blockHeight >= 50 ? (isTablet ? 8 : 6) : 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (totalMeetings > 2 || constraints.maxHeight < 25) {
                return Text(
                  meeting.title ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meeting.title ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                          maxLines: blockHeight >= 60 ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showAttendees) ...[
                          SizedBox(height: blockHeight >= 50 ? 2 : 1),
                          Text(
                            meeting.attendees?.join(', ') ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: attendeesFontSize,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: blockHeight >= 50 ? 8 : 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showTime) ...[
                        Text(
                          '${meeting.startTime?.split(' ')[0]} - ${meeting.endTime?.split(' ')[0]}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: timeFontSize,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                      if (showLocation) ...[
                        SizedBox(height: blockHeight >= 50 ? 2 : 1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              meeting.location == MeetingLocation.online
                                  ? Icons.videocam_rounded
                                  : Icons.location_on_rounded,
                              color: accentColor.withValues(alpha: 0.7),
                              size: blockHeight >= 50 ? 12 : 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              meeting.location == MeetingLocation.online
                                  ? 'Online'
                                  : 'On-site',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accentColor.withValues(alpha: 0.7),
                                fontSize: locationFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(
    ThemeData theme,
    bool isTablet,
    double timeSlotHeight,
  ) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final minutesPerPixel = timeSlotHeight / 60.0;
    final topPosition = (currentMinutes + 30) * minutesPerPixel;
    final leftOffset = isTablet ? 60.0 : 50.0;
    if (!_isSameDay(_selectedDate, now)) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: topPosition,
      left: leftOffset + 12,
      right: 12,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Container(height: 2, color: Colors.red)),
        ],
      ),
    );
  }

  String _formatHour24(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  double _getInitialScrollOffset(double timeSlotHeight) {
    final now = DateTime.now();
    if (_isSameDay(_selectedDate, now)) {
      final currentHour = now.hour;
      final scrollToHour = (currentHour - 2).clamp(0, 21);
      return scrollToHour * timeSlotHeight;
    } else {
      return 8 * timeSlotHeight;
    }
  }

  void _showMeetingDetails(Meeting meeting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMeetingDetailsModal(meeting),
    );
  }

  Widget _buildMeetingDetailsModal(Meeting meeting) {
    final theme = Theme.of(context);
    final accentColor = _getMeetingColor(
      meeting.location ?? MeetingLocation.online,
      theme,
    );
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meeting.title ?? '',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              meeting.location == MeetingLocation.online
                                  ? Icons.videocam_rounded
                                  : Icons.location_on_rounded,
                              color: accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              meeting.location == MeetingLocation.online
                                  ? 'Online'
                                  : 'On-site',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Time',
                    '${meeting.startTime} - ${meeting.endTime}',
                    theme,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.people_outline_rounded,
                    'Attendees',
                    meeting.attendees?.join(', ') ?? '',
                    theme,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _editMeeting(meeting);
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final shouldDelete = await _showDeleteConfirmation(
                              meeting,
                            );
                            if (shouldDelete) {
                              _deleteMeeting(meeting);
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editMeeting(Meeting meeting) {
    HapticFeedback.mediumImpact();
    context.pushNamed('addSchedule', extra: meeting);
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

  Color _getMeetingColor(MeetingLocation type, ThemeData theme) {
    switch (type) {
      case MeetingLocation.online:
        return theme.colorScheme.primary;
      case MeetingLocation.onsite:
        return Colors.green;
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

  String _formatMonthYear(DateTime date) {
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
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatDayHeader(DateTime date) {
    List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[date.weekday - 1]}, ${_formatDate(date)}';
  }

  String _getWeekTitle(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (weekStart.month == weekEnd.month) {
      return '${_formatDate(weekStart)} - ${weekEnd.day}, ${weekStart.year}';
    } else {
      return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
    }
  }

  int _getMeetingTimeInMinutes(String timeString) {
    final parts = timeString.split(':');
    if (parts.length < 2) return 540;
    final hour = int.tryParse(parts[0]) ?? 9;
    final minutePart = parts[1].split(' ')[0];
    final minute = int.tryParse(minutePart) ?? 0;
    final isAM = timeString.toUpperCase().contains('AM');
    int hour24 = hour;
    if (isAM) {
      hour24 = hour == 12 ? 0 : hour;
    } else {
      hour24 = hour == 12 ? 12 : hour + 12;
    }
    return hour24 * 60 + minute;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final RegExp regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
        caseSensitive: false,
      );
      final match = regex.firstMatch(timeString);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {}
    return const TimeOfDay(hour: 9, minute: 0);
  }

  Widget _buildCalendarView() {
    return CalendarView(
      key: const ValueKey('calendar'),
      selectedDate: _selectedDate,
      onDateSelected: _selectDateFromCalendar,
      onBack: _toggleCalendarView,
    );
  }
}
