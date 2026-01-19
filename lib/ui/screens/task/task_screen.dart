import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/managers/task_manager.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/calendar_view.dart';
import 'package:frontend/utils/data_key.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/task.dart';
import '../../../models/taskpriority.dart';
import '../../../utils/localization.dart';
import 'package:intl/intl.dart';

class TaskScreen extends StatefulWidget {
  final List<Task> tasks;
  final DateTime date;
  const TaskScreen({super.key, required this.tasks, required this.date});
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentWeekStart = DateTime.now();
  bool _showingCalendarView = false;
  String _selectedFilter = "All";
  bool _isLoading = false;
  List<String> _filters = [];
  List<Task> _tasks = <Task>[];
  @override
  void initState() {
    super.initState();
    _tasks = widget.tasks;
    _selectedDate = widget.date;
    _currentWeekStart = _getWeekStart(_selectedDate);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTasksForDate(_selectedDate);
      _setupTaskListener();
    });
  }

  void _setupTaskListener() {
    final manager = TaskManager();
    if (manager.isInitialized) {
      final listenable = manager.listenable();
      if (listenable != null) {
        listenable.addListener(() {
          if (mounted) {
            _getTasksForDate(_selectedDate);
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _getTasksForDate(DateTime date) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final manager = TaskManager();
      if (manager.isInitialized) {
        final tasks = manager.getTaskOfDate(date);
        if (mounted) {
          setState(() {
            _tasks = tasks;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _tasks = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tasks = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _toggleCalendarView() {
    setState(() {
      _showingCalendarView = !_showingCalendarView;
    });
  }

  void _selectDateFromCalendar(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _currentWeekStart = _getWeekStart(date);
      _showingCalendarView = false;
    });
    await _getTasksForDate(date);
  }

  void _toggleTaskCompletion(
    Task task,
    DateTime selectedDate,
    bool isCompleted,
  ) async {
    if (task.isCompleted == true) {
         return; 
    }

    HapticFeedback.lightImpact();

    if (isCompleted) {
        final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
                return AlertDialog(
                    title: Text(AppLocalizations.of(context).completeTask),
                    content: Text(AppLocalizations.of(context).confirmCompleteTask),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(AppLocalizations.of(context).cancel),
                        ),
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(AppLocalizations.of(context).confirm),
                        ),
                    ],
                );
            },
        );

        if (confirm != true) return;
    }

    try {
      final manager = TaskManager();
      if (manager.isInitialized) {
        await manager.addOrUpdateTask(
          task.copyWith(
            isCompleted: isCompleted,
            dueDate: selectedDate.toIso8601String(),
          ),
        );
        if (mounted) {
             _getTasksForDate(_selectedDate);
        }
      }
      try {
        await context.read<TaskProvider>().updateTask(
          id: task.id!,
          isCompleted: isCompleted,
        );
      } catch (e) {}
    } catch (e) {}
  }

  void _editTask(Task task) async {
    if (task.isCompleted == true) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context).completedTasksCannotBeEdited),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
            ),
        );
        return;
    }

    HapticFeedback.mediumImpact();
    await context.pushNamed('addTask', extra: task);
    await _getTasksForDate(_selectedDate);
  }

  void _deleteTask(Task task, DateTime selectedDate) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    final snackBar = SnackBar(
      content: Text('Task "${task.title}" deleted'),
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.white,
        onPressed: () {
          setState(() {
            _tasks.add(task);
            _tasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
          });
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    await Future.delayed(const Duration(seconds: 4));
    bool taskStillDeleted = !_tasks.any((t) => t.id == task.id);
    if (taskStillDeleted) {
      await _permanentlyDeleteTask(task, selectedDate);
    }
  }

  Future<void> _permanentlyDeleteTask(Task task, DateTime selectedDate) async {
    try {
      await context.read<TaskProvider>().deleteTask(task.id!);
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
    } catch (e) {}
  }

  List<Task> get _filteredTasks {
    final l10n = AppLocalizations.of(context);
    if (_selectedFilter == 'In Progress' ||
        _selectedFilter == l10n.inProgress) {
      return _tasks.where((task) => task.isCompleted != true).toList();
    } else if (_selectedFilter == 'Completed' ||
        _selectedFilter == l10n.completed) {
      return _tasks.where((task) => task.isCompleted == true).toList();
    } else {
      return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    final l10n = AppLocalizations.of(context);

    if (_filters.isEmpty) {
      _filters = [l10n.all, l10n.inProgress, l10n.completed];
      _selectedFilter = l10n.all;
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        drawer: const SideMenu(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
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
                          : SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              key: const ValueKey('tasks'),
                              children: [
                                _buildHeader(isTablet, isLargeScreen),
                                _buildWeekNavigation(Theme.of(context), isTablet),
                                _buildWeekDaysHeader(Theme.of(context), isTablet),
                                _buildProgressCard(isTablet),
                                _buildFilterTabs(isTablet),
                                Expanded(child: _buildTasksList(isTablet)),
                              ],
                            ),
                          ),
                ),
              ),
              const DraggableMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.all(
        isLargeScreen
            ? 24
            : isTablet
            ? 20
            : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).tasks,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize:
                        isLargeScreen
                            ? 32
                            : isTablet
                            ? 30
                            : 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${_tasks.length} ${AppLocalizations.of(context).tasks}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Row(
            children: [
              _buildHeaderButton(
                Icons.calendar_month_rounded,
                _toggleCalendarView,
                Theme.of(context),
                isTablet,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              _buildHeaderButton(
                Icons.add,
                () async {
                  await context.pushNamed('addTask');
                  await _getTasksForDate(_selectedDate);
                },
                Theme.of(context),
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
    bool isTablet, {
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        onLongPress: onLongPress,
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

  Widget _buildCalendarView() {
    return CalendarView(
      key: const ValueKey('calendar'),
      selectedDate: _selectedDate,
      onDateSelected: _selectDateFromCalendar,
      onBack: _toggleCalendarView,
    );
  }

  Widget _buildProgressCard(bool isTablet) {
    final completedTasks = _tasks.where((task) => task.isCompleted!).length;
    final totalTasks = _tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: 12,
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).todayProgress,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedTasks of $totalTasks ${AppLocalizations.of(context).completed}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(
                      AppLocalizations.of(context).high,
                      _getHighPriorityCount(),
                      Colors.red,
                      isTablet,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildProgressCircle(progress),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color, bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isTablet ? 8 : 6,
          height: isTablet ? 8 : 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: isTablet ? 12 : 11,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCircle(double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(bool isTablet) {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: isTablet ? 16 : 12),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15)
                        : Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3)
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList(bool isTablet) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: 8,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildShimmerItem(context, isTablet);
      },
    );
  }

  Widget _buildShimmerItem(context, bool isTablet) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
      highlightColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.1),
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 28 : 24,
              height: isTablet ? 28 : 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 120,
                        height: isTablet ? 16 : 14,
                        color: Colors.white,
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: isTablet ? 20 : 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 6 : 4),
                  Container(
                    width: 200,
                    height: isTablet ? 14 : 12,
                    color: Colors.white,
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: isTablet ? 24 : 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 50,
                        height: isTablet ? 14 : 12,
                        color: Colors.white,
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

  Widget _buildTasksList(bool isTablet) {
    if (_isLoading) {
      return _buildShimmerList(isTablet);
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: 8,
      ),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return _buildTaskItem(task, isTablet);
      },
    );
  }

  Widget _buildTaskItem(Task task, bool isTablet) {
    return Dismissible(
      key: Key(task.title! + task.dueDate!),
      background: _buildSwipeBackground(isEdit: true, isTablet: isTablet),
      secondaryBackground: _buildSwipeBackground(
        isEdit: false,
        isTablet: isTablet,
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _editTask(task);
        } else {
          _deleteTask(task, _selectedDate);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editTask(task);
          return false;
        } else {
          return await _showDeleteConfirmation(task);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
        decoration: BoxDecoration(
          color:
              task.isCompleted!
                  ? Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.03)
                  : Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                task.isCompleted!
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap:
                () => _showTaskDetails(task, isTablet),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Row(
                children: [
                  GestureDetector(
                      onTap: () => _toggleTaskCompletion(
                          task,
                          _selectedDate,
                          !task.isCompleted!,
                      ),
                      child: _buildCheckboxButton(task, isTablet),
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
                                task.title!,
                                style: TextStyle(
                                  color:
                                      task.isCompleted!
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5)
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  decoration:
                                      task.isCompleted!
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                ),
                              ),
                            ),
                            _buildPriorityChip(task, isTablet),
                          ],
                        ),
                        if (task.description?.isNotEmpty ?? false) ...[
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            task.description!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(
                                alpha: task.isCompleted! ? 0.4 : 0.6,
                              ),
                              fontSize: isTablet ? 14 : 12,
                              decoration:
                                  task.isCompleted!
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: isTablet ? 12 : 8),
                        Row(
                          children: [
                            _buildCategoryChip(task, isTablet),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(
                                    alpha: task.isCompleted! ? 0.4 : 0.6,
                                  ),
                                  size: isTablet ? 16 : 14,
                                ),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  DataKey.formatTime(task.dueDate!),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withValues(
                                      alpha: task.isCompleted! ? 0.4 : 0.6,
                                    ),
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildSwipeBackground({required bool isEdit, required bool isTablet}) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color:
            isEdit
                ? Colors.blue.withValues(alpha: 0.8)
                : Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
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
                isEdit
                    ? AppLocalizations.of(context).edit
                    : AppLocalizations.of(context).delete,
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

  Future<bool> _showDeleteConfirmation(Task task) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  AppLocalizations.of(context).deleteTask,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  '${AppLocalizations.of(context).areYouSureYouWantToDelete} "${task.title}"?',
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
                      AppLocalizations.of(context).cancel,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      AppLocalizations.of(context).delete,
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

  Widget _buildCheckboxButton(Task task, bool isTablet) {
    final size = isTablet ? 28.0 : 24.0;
    // Increase hitbox with outer transparent container
    return Container(
      padding: const EdgeInsets.all(12.0), // Hitbox padding
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: task.isCompleted! ? Colors.green : Colors.transparent, 
          shape: BoxShape.circle,
          border: Border.all(
            color:
                task.isCompleted!
                    ? Colors.green
                    : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child:
              task.isCompleted!
                  ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: isTablet ? 16 : 14,
                    key: const ValueKey('check'),
                  )
                  : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(Task task, bool isTablet) {
    Color color;
    String label;
    switch (task.priority) {
      case TaskPriority.high:
        color = Colors.red.shade400;
        label = AppLocalizations.of(context).high.toUpperCase();
        break;
      case TaskPriority.medium:
        color = Colors.orange.shade400;
        label = AppLocalizations.of(context).medium.toUpperCase();
        break;
      default:
        color = Colors.green.shade400;
        label = AppLocalizations.of(context).low.toUpperCase();
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 6,
        vertical: isTablet ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color:
            (task.isCompleted!
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              task.isCompleted!
                  ? color.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: task.isCompleted! ? color.withValues(alpha: 0.6) : color,
          fontSize: isTablet ? 11 : 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Task task, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: task.isCompleted! ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(
            alpha: task.isCompleted! ? 0.2 : 0.3,
          ),
          width: 1,
        ),
      ),
      child: Text(
        task.category!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary.withValues(
            alpha: task.isCompleted! ? 0.6 : 0.8,
          ),
          fontSize: isTablet ? 12 : 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getDateLabel() {
    return DateFormat('EEEE d MMM, y').format(_selectedDate);
  }

  void _showTaskDetails(Task task, bool isTablet) {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.task_alt_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title ?? '',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPriorityChip(task, isTablet),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  if (task.description?.isNotEmpty ?? false) ...[
                      _buildDetailRow(
                        Icons.description_outlined,
                        AppLocalizations.of(context).description, 
                        task.description!,
                        theme,
                      ),
                      const SizedBox(height: 24),
                  ],

                  _buildDetailRow(
                  Icons.calendar_today_rounded,
                  AppLocalizations.of(context).dateAndTime,
                  "${DateFormat('EEEE d MMM, y').format(_selectedDate)} ${DataKey.formatTime(task.dueDate!)}",
                  theme,
                ),
                const SizedBox(height: 24),
                  
                  _buildDetailRow(
                    Icons.category_outlined,
                    AppLocalizations.of(context).category,
                    task.category ?? 'General',
                    theme,
                  ),

                  const SizedBox(height: 48),

                  Row(
                    children: [
                      if (!task.isCompleted!) 
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _editTask(task);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: Text(AppLocalizations.of(context).edit),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      if (!task.isCompleted!) 
                           const SizedBox(width: 12),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final shouldDelete = await _showDeleteConfirmation(
                              task,
                            );
                            if (shouldDelete) {
                              _deleteTask(task, _selectedDate);
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(AppLocalizations.of(context).delete),
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
          ],
        ),
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

  int _getHighPriorityCount() =>
      _tasks.where((t) => t.priority == TaskPriority.high).length;

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _goToToday() async {
    setState(() {
      _selectedDate = DateTime.now();
      _currentWeekStart = _getWeekStart(DateTime.now());
    });
    await _getTasksForDate(_selectedDate);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d', AppLocalizations.of(context).locale.toString()).format(date);
  }

  String _formatDayName(DateTime date) {
    return DateFormat('E', AppLocalizations.of(context).locale.toString()).format(date);
  }

  String _getWeekTitle(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
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
        onTap: () async {
          setState(() {
            _selectedDate = day;
          });
          await _getTasksForDate(day);
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
}
