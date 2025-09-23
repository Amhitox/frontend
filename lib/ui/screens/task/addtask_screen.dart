import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/utils/localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../models/taskpriority.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? editingTask;
  const AddTaskScreen({super.key, this.editingTask});
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TaskPriority _selectedPriority = TaskPriority.medium;
  String _selectedCategoryKey = 'work';
  bool _showCustomCategoryField = false;
  Task newTask = Task();
  bool isEditMode = false;
  final List<String> _categoryKeys = [
    'work',
    'personal',
    'finance',
    'health',
    'education',
    'other',
  ];
  List<String> _categories = [];
  bool _isSaving = false;
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
    if (widget.editingTask != null) {
      isEditMode = true;
      _titleController.text = widget.editingTask!.title!;
      _descriptionController.text = widget.editingTask!.description ?? '';
      _selectedCategoryKey = widget.editingTask!.category!;
      _selectedPriority = widget.editingTask!.priority!;
      if (!_categoryKeys.contains(_selectedCategoryKey)) {
        _showCustomCategoryField = true;
        _customCategoryController.text = _selectedCategoryKey;
        _selectedCategoryKey = 'other';
      }
      try {
        final isoString = widget.editingTask!.dueDate!;
        DateTime utcDateTime = DateTime.parse(isoString);
        _selectedDate = DateTime(
          utcDateTime.year,
          utcDateTime.month,
          utcDateTime.day,
        );
        _selectedTime = TimeOfDay(
          hour: utcDateTime.hour,
          minute: utcDateTime.minute,
        );
      } catch (e) {
        _selectedTime = TimeOfDay.now();
      }
    }
    _slideController.forward();
    _fadeController.forward();

    // Initialize categories with translated values
    _categories = [
      AppLocalizations.of(context).work,
      AppLocalizations.of(context).personal,
      AppLocalizations.of(context).finance,
      AppLocalizations.of(context).health,
      AppLocalizations.of(context).education,
      AppLocalizations.of(context).other,
    ];

    // Set default category key
    if (_selectedCategoryKey.isEmpty) {
      _selectedCategoryKey = 'work';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      _showFeedback(
        AppLocalizations.of(context).pleaseEnterATaskTitle,
        isError: true,
      );
      return;
    }
    if (_showCustomCategoryField &&
        _customCategoryController.text.trim().isEmpty) {
      _showFeedback(
        AppLocalizations.of(context).pleaseEnterACustomCategoryName,
        isError: true,
      );
      return;
    }
    final now = DateTime.now();
    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (selectedDateOnly.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).taskDateCannotBeInThePast),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (selectedDateOnly.isAtSameMomentAs(today)) {
      final oneHourFromNow = now.add(const Duration(hours: 1));
      if (combinedDateTime.isBefore(oneHourFromNow)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).taskTimeMustBeAtLeastOneHourFromNow,
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }
    setState(() => _isSaving = true);
    if (!isEditMode) {
      await context.read<TaskProvider>().addTask(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _selectedPriority.toString().split('.').last,
        _selectedDate,
        _selectedTime,
        false,
        _showCustomCategoryField
            ? _customCategoryController.text.trim().toLowerCase()
            : _selectedCategoryKey,
      );
    } else {
      await context.read<TaskProvider>().updateTask(
        id: widget.editingTask!.id!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority.toString().split('.').last,
        date: _selectedDate,
        time: _selectedTime,
        isCompleted: widget.editingTask!.isCompleted,
        category:
            _showCustomCategoryField
                ? _customCategoryController.text.trim().toLowerCase()
                : _selectedCategoryKey,
      );
    }
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1000));
    _showFeedback(
      widget.editingTask != null
          ? AppLocalizations.of(context).taskUpdatedSuccessfully
          : AppLocalizations.of(context).taskCreatedSuccessfully,
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) context.pop();
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
                context.goNamed('task');
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
              widget.editingTask != null
                  ? AppLocalizations.of(context).editTask
                  : AppLocalizations.of(context).newTask,
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
            label: AppLocalizations.of(context).taskTitle,
            hint: AppLocalizations.of(context).whatNeedsToBeDone,
            icon: Icons.task_alt_rounded,
            theme: theme,
            isTablet: isTablet,
            isLargeScreen: isLargeScreen,
          ),
          SizedBox(height: isTablet ? 24 : 20),
          _buildTextField(
            controller: _descriptionController,
            label: AppLocalizations.of(context).description,
            hint: AppLocalizations.of(context).addDetailsAboutThisTaskOptional,
            icon: Icons.description_rounded,
            maxLines: 3,
            theme: theme,
            isTablet: isTablet,
            isLargeScreen: isLargeScreen,
          ),
          SizedBox(height: isTablet ? 24 : 20),
          _buildDateTimeSection(theme, isTablet, isLargeScreen),
          SizedBox(height: isTablet ? 24 : 20),
          _buildCategorySection(theme, isTablet, isLargeScreen),
          if (_showCustomCategoryField) ...[
            SizedBox(height: isTablet ? 16 : 12),
            _buildTextField(
              controller: _customCategoryController,
              label: AppLocalizations.of(context).customCategory,
              hint: AppLocalizations.of(context).enterYourCustomCategoryName,
              icon: Icons.label_rounded,
              theme: theme,
              isTablet: isTablet,
              isLargeScreen: isLargeScreen,
            ),
          ],
          SizedBox(height: isTablet ? 24 : 20),
          _buildPrioritySection(theme, isTablet, isLargeScreen),
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
            onTapOutside: (event) {
              FocusScope.of(context).unfocus();
            },
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
          AppLocalizations.of(context).dueDateTime,
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
          FocusScope.of(context).unfocus();
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
    final padding =
        isLargeScreen
            ? 16.0
            : isTablet
            ? 14.0
            : 12.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        onTap: () async {
          HapticFeedback.lightImpact();
          FocusScope.of(context).unfocus();
          final time = await showTimePicker(
            context: context,
            initialTime: _selectedTime,
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
          if (time != null) {
            setState(() => _selectedTime = time);
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
                AppLocalizations.of(context).time,
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
                _selectedTime.format(context),
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

  Widget _buildCategorySection(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).category,
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
          runSpacing: isTablet ? 12 : 8,
          children:
              _categoryKeys.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryKey = entry.value;
                final categoryDisplay = _categories[index];
                final isSelected = _selectedCategoryKey == categoryKey;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategoryKey = categoryKey;
                        _showCustomCategoryField = categoryKey == 'other';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isLargeScreen
                                ? 20
                                : isTablet
                                ? 16
                                : 14,
                        vertical:
                            isLargeScreen
                                ? 12
                                : isTablet
                                ? 10
                                : 8,
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
                          width: isSelected ? 2 : 1,
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
                        categoryDisplay,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                          fontSize:
                              isLargeScreen
                                  ? 15
                                  : isTablet
                                  ? 14
                                  : 13,
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

  Widget _buildPrioritySection(
    ThemeData theme,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).priority,
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
          children:
              TaskPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                final color = _getPriorityColor(priority);
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPriority = priority);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.symmetric(
                          horizontal: isTablet ? 6 : 4,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical:
                              isLargeScreen
                                  ? 16
                                  : isTablet
                                  ? 14
                                  : 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? color.withValues(alpha: 0.15)
                                  : theme.colorScheme.surface.withValues(
                                    alpha: 0.8,
                                  ),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 16 : 12,
                          ),
                          border: Border.all(
                            color:
                                isSelected
                                    ? color.withValues(alpha: 0.4)
                                    : theme.colorScheme.outline.withValues(
                                      alpha: 0.1,
                                    ),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isTablet ? 8 : 6,
                              height: isTablet ? 8 : 6,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? color
                                        : color.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: isTablet ? 10 : 8),
                            Text(
                              _getPriorityLabel(priority),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isSelected
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                fontSize:
                                    isLargeScreen
                                        ? 15
                                        : isTablet
                                        ? 14
                                        : 13,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                              ),
                            ),
                          ],
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          onTap: _isSaving ? null : _saveTask,
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
              color:
                  _isSaving
                      ? theme.colorScheme.primary.withValues(alpha: 0.6)
                      : theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              boxShadow:
                  _isSaving
                      ? []
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
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: isTablet ? 22 : 18,
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Text(
                            widget.editingTask != null
                                ? AppLocalizations.of(context).updateTask
                                : AppLocalizations.of(context).createTask,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontSize:
                                  isLargeScreen
                                      ? 17
                                      : isTablet
                                      ? 16
                                      : 15,
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

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade400;
      case TaskPriority.medium:
        return Colors.orange.shade400;
      case TaskPriority.low:
        return Colors.green.shade400;
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppLocalizations.of(context).high;
      case TaskPriority.medium:
        return AppLocalizations.of(context).medium;
      case TaskPriority.low:
        return AppLocalizations.of(context).low;
    }
  }
}
