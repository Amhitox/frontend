import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../models/meeting.dart';
import '../../../models/meetingtype.dart';

class AddScheduleScreen extends StatefulWidget {
  final Meeting? meeting;
  const AddScheduleScreen({super.key, this.meeting});

  @override
  _AddScheduleScreenState createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _attendeesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(
    hour: TimeOfDay.now().hour + 1,
  );
  MeetingType _selectedType = MeetingType.internal;

  bool _isSaving = false;
  bool _isEditMode = false;

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

    // Populate form if editing existing meeting
    if (widget.meeting != null) {
      _isEditMode = true;
      _populateFormWithMeetingData();
    }

    _slideController.forward();
    _fadeController.forward();
  }

  void _populateFormWithMeetingData() {
    final meeting = widget.meeting!;
    _titleController.text = meeting.title;
    _attendeesController.text = meeting.attendees.join(', ');
    _selectedType = meeting.type;

    // Parse time from meeting.time string (e.g., "09:00 AM")
    _startTime = _parseTimeString(meeting.time);

    // Parse duration and calculate end time
    _endTime = _calculateEndTime(_startTime, meeting.duration);
  }

  TimeOfDay _parseTimeString(String timeStr) {
    // Parse "09:00 AM" format
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (parts[1].toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  TimeOfDay _calculateEndTime(TimeOfDay startTime, String duration) {
    // Parse duration like "2h", "1h 30m", "45m"
    try {
      int totalMinutes = 0;
      final regex = RegExp(r'(\d+)([hm])');
      final matches = regex.allMatches(duration);

      for (final match in matches) {
        final value = int.parse(match.group(1)!);
        final unit = match.group(2)!;

        if (unit == 'h') {
          totalMinutes += value * 60;
        } else if (unit == 'm') {
          totalMinutes += value;
        }
      }

      final endMinutes = startTime.hour * 60 + startTime.minute + totalMinutes;
      return TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
    } catch (e) {
      return startTime.replacing(hour: startTime.hour + 1);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _attendeesController.dispose();
    super.dispose();
  }

  void _saveSchedule() async {
    if (_titleController.text.trim().isEmpty) {
      _showFeedback('Please enter a title', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1000));
    Meeting? meeting;
    // Create the meeting object with form data
    if (mounted) {
      meeting = Meeting(
        title: _titleController.text.trim(),
        time: _startTime.format(context),
        duration: _calculateDuration(),
        attendees:
            _attendeesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        type: _selectedType,
      );
    }

    _showFeedback(
      _isEditMode
          ? 'Meeting updated successfully'
          : 'Schedule added successfully',
    );

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      // Pass the meeting data back when navigating
      context.go(
        '/calendar',
        extra: {
          'action': _isEditMode ? 'update' : 'add',
          'meeting': meeting,
          'originalMeeting': widget.meeting, // For update operations
        },
      );
    }
  }

  String _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes - startMinutes;

    if (durationMinutes <= 0) return "0m";

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return "${hours}h ${minutes}m";
    } else if (hours > 0) {
      return "${hours}h";
    } else {
      return "${minutes}m";
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor:
            isError
                ? Colors.red.withValues(alpha: 0.9)
                : Colors.green.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(milliseconds: isError ? 3000 : 2000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(theme, isTablet, isLargeScreen),
                  Expanded(child: _buildForm(theme, isTablet, isLargeScreen)),
                  _buildSaveButton(theme, isTablet, isLargeScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isTablet, bool isLargeScreen) {
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
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/calendar');
              },
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
              _isEditMode ? 'Edit Meeting' : 'New Schedule',
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
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme, bool isTablet, bool isLargeScreen) {
    final padding =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        children: [
          SizedBox(height: isTablet ? 24 : 20),
          _buildTextField(
            controller: _titleController,
            label: 'Meeting Title',
            hint: 'What is this meeting about?',
            icon: Icons.title_rounded,
            theme: theme,
            isTablet: isTablet,
            isLargeScreen: isLargeScreen,
          ),
          SizedBox(height: isTablet ? 24 : 20),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Meeting agenda or details (optional)',
            icon: Icons.description_rounded,
            maxLines: 3,
            theme: theme,
            isTablet: isTablet,
            isLargeScreen: isLargeScreen,
          ),
          SizedBox(height: isTablet ? 24 : 20),
          _buildDateTimeSection(theme, isTablet, isLargeScreen),
          SizedBox(height: isTablet ? 24 : 20),
          _buildTypeSelector(theme, isTablet, isLargeScreen),
          SizedBox(height: isTablet ? 24 : 20),
          _buildTextField(
            controller: _attendeesController,
            label: 'Attendees',
            hint: 'Enter email addresses separated by commas',
            icon: Icons.people_rounded,
            theme: theme,
            isTablet: isTablet,
            isLargeScreen: isLargeScreen,
          ),
          SizedBox(height: isTablet ? 24 : 20),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required ThemeData theme,
    required bool isTablet,
    required bool isLargeScreen,
  }) {
    final padding =
        isLargeScreen
            ? 20.0
            : isTablet
            ? 18.0
            : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize:
                isLargeScreen
                    ? 14
                    : isTablet
                    ? 13
                    : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
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
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize:
                  isLargeScreen
                      ? 16
                      : isTablet
                      ? 15
                      : 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize:
                    isLargeScreen
                        ? 16
                        : isTablet
                        ? 15
                        : 14,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.only(right: isTablet ? 12 : 8),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  size: isTablet ? 22 : 20,
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: isTablet ? 56 : 48,
                minHeight: isTablet ? 56 : 48,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: maxLines > 1 ? padding : (isTablet ? 16 : 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATE & TIME',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize:
                isLargeScreen
                    ? 14
                    : isTablet
                    ? 13
                    : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Row(
          children: [
            Expanded(child: _buildDateSelector(theme, isTablet, isLargeScreen)),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(child: _buildTimeSelector(theme, isTablet, isLargeScreen)),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final padding =
        isLargeScreen
            ? 20.0
            : isTablet
            ? 18.0
            : 16.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        onTap: () async {
          HapticFeedback.lightImpact();
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) {
              return Theme(
                data: theme.copyWith(
                  dialogTheme: DialogThemeData(
                    backgroundColor: theme.colorScheme.surface,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            setState(() => _selectedDate = date);
            HapticFeedback.selectionClick();
          }
        },
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
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
                padding: EdgeInsets.all(isTablet ? 8 : 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: theme.colorScheme.primary,
                  size: isTablet ? 20 : 18,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize:
                        isLargeScreen
                            ? 16
                            : isTablet
                            ? 15
                            : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: isTablet ? 16 : 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTimePicker(
            'Start',
            _startTime,
            (t) => setState(() => _startTime = t),
            theme,
            isTablet,
            isLargeScreen,
          ),
        ),
        SizedBox(width: isTablet ? 12 : 8),
        Expanded(
          child: _buildTimePicker(
            'End',
            _endTime,
            (t) => setState(() => _endTime = t),
            theme,
            isTablet,
            isLargeScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final padding =
        isLargeScreen
            ? 14.0
            : isTablet
            ? 12.0
            : 10.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        onTap: () async {
          HapticFeedback.lightImpact();
          final selectedTime = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (context, child) {
              return Theme(
                data: theme.copyWith(
                  dialogTheme: DialogThemeData(
                    backgroundColor: theme.colorScheme.surface,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (selectedTime != null) {
            onChanged(selectedTime);
            HapticFeedback.selectionClick();
          }
        },
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
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
          child: Column(
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize:
                      isLargeScreen
                          ? 13
                          : isTablet
                          ? 12
                          : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Text(
                time.format(context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize:
                      isLargeScreen
                          ? 16
                          : isTablet
                          ? 15
                          : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEETING TYPE',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize:
                isLargeScreen
                    ? 14
                    : isTablet
                    ? 13
                    : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Wrap(
          spacing: isTablet ? 12 : 8,
          runSpacing: isTablet ? 8 : 6,
          children:
              MeetingType.values.map((type) {
                final isSelected = _selectedType == type;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                    onTap: () {
                      setState(() => _selectedType = type);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isLargeScreen
                                ? 24
                                : isTablet
                                ? 20
                                : 16,
                        vertical:
                            isLargeScreen
                                ? 14
                                : isTablet
                                ? 12
                                : 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                )
                                : theme.colorScheme.surface.withValues(
                                  alpha: 0.8,
                                ),
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  )
                                  : theme.colorScheme.outline.withValues(
                                    alpha: 0.1,
                                  ),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                      ),
                      child: Text(
                        _getTypeLabel(type),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color:
                              isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                          fontSize:
                              isLargeScreen
                                  ? 14
                                  : isTablet
                                  ? 13
                                  : 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme, bool isTablet, bool isLargeScreen) {
    final padding =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          onTap: _isSaving ? null : _saveSchedule,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height:
                isLargeScreen
                    ? 56
                    : isTablet
                    ? 52
                    : 48,
            decoration: BoxDecoration(
              gradient:
                  _isSaving
                      ? null
                      : LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
              color:
                  _isSaving
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
                      : null,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              boxShadow:
                  _isSaving
                      ? null
                      : [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
            ),
            child: Center(
              child:
                  _isSaving
                      ? SizedBox(
                        width: isTablet ? 24 : 20,
                        height: isTablet ? 24 : 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: isTablet ? 22 : 20,
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Text(
                            _isEditMode ? 'Update Meeting' : 'Add Schedule',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontSize:
                                  isLargeScreen
                                      ? 16
                                      : isTablet
                                      ? 15
                                      : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(MeetingType type) {
    switch (type) {
      case MeetingType.boardMeeting:
        return 'Board Meeting';
      case MeetingType.client:
        return 'Client';
      case MeetingType.internal:
        return 'Internal';
      case MeetingType.strategy:
        return 'Strategy';
    }
  }
}
