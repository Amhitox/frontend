import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalendarView extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onBack;

  const CalendarView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onBack,
  });

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  bool _showingCalendarView = false;
  late DateTime _selectedDate;
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  void _toggleCalendarView() {
    setState(() {
      _showingCalendarView = !_showingCalendarView;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    return Column(
      children: [
        _buildCalendarViewHeader(theme, isTablet, isLargeScreen),
        Expanded(child: _buildMonthCalendar(theme, isTablet, isLargeScreen)),
      ],
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
                child: GestureDetector(
                  onTap: () {
                    widget.onBack();
                  },
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: theme.colorScheme.onSurface,
                    size: isTablet ? 20 : 16,
                  ),
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

  void _selectDateFromCalendar(DateTime date) {
    setState(() {
      _selectedDate = date;
      _showingCalendarView = false;
    });
    widget.onDateSelected(date);
    HapticFeedback.mediumImpact();
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
