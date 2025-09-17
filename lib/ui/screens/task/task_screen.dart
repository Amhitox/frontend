import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/helpers/local_tasks.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/calendar_view.dart';
import 'package:frontend/utils/data_key.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/task.dart';
import '../../../models/taskpriority.dart';

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
  bool _showingCalendarView = false;
  String _selectedFilter = "All";
  bool _isLoading = false;

  final List<String> _filters = ["All", "In Progress", "Completed"];

  List<Task> _tasks = <Task>[];

  @override
  void initState() {
    super.initState();
    _tasks = widget.tasks;
    _selectedDate = widget.date;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      _getTasksForDate(_selectedDate);
    });
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
    final selectedDateKey = DataKey.dateKey(date);
    final now = DateTime.now();

    final start = now.subtract(const Duration(days: 7));
    final end = now.add(const Duration(days: 7));

    if (!date.isBefore(start) && !date.isAfter(end)) {
      final tasksMap = await getLocalTasks(date);

      final filteredTasks =
          tasksMap[selectedDateKey]
              ?.map((taskJson) => Task.fromJson(jsonDecode(taskJson)))
              .toList() ??
          <Task>[];
      if (mounted) {
        setState(() {
          _tasks = filteredTasks;
          _isLoading = false;
        });
      }
    } else {
      final tasks = await context.read<TaskProvider>().getTasks(
        selectedDateKey,
      );
      if (mounted) {
        setState(() {
          _tasks = tasks;
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
      _showingCalendarView = false;
    });

    await _getTasksForDate(date);
  }

  void _toggleTaskCompletion(
    Task task,
    DateTime selectedDate,
    bool isCompleted,
  ) async {
    HapticFeedback.lightImpact();

    final pref = await SharedPreferences.getInstance();
    final user = User.fromJson(jsonDecode(pref.getString('user')!));
    final tasksJson = pref.getString('tasks_${user.id}');
    final selectedDateKey = DataKey.dateKey(selectedDate);

    Map<String, List<String>> tasksMap =
        tasksJson != null
            ? Map<String, List<String>>.from(
              jsonDecode(
                tasksJson,
              ).map((k, v) => MapEntry(k, List<String>.from(v))),
            )
            : {};

    if (!tasksMap.containsKey(selectedDateKey)) {
      return;
    }

    List<String> tasks = tasksMap[selectedDateKey]!;

    bool taskFound = false;
    for (int i = 0; i < tasks.length; i++) {
      Map<String, dynamic> taskJson = jsonDecode(tasks[i]);

      if (taskJson['id'] == task.id) {
        taskJson['isCompleted'] = isCompleted;

        tasks[i] = jsonEncode(taskJson);
        taskFound = true;
        break;
      }
    }

    if (taskFound) {
      final updatedTasksJson = jsonEncode(tasksMap);
      await pref.setString('tasks_${user.id}', updatedTasksJson);
      setState(() {
        _tasks =
            tasksMap[selectedDateKey]!
                .map((taskJson) => Task.fromJson(jsonDecode(taskJson)))
                .toList();
      });
    } else {
      print('Task ${task.id} not found on $selectedDateKey');
    }
    await _getTasksForDate(_selectedDate);
    await context.read<TaskProvider>().updateTask(
      id: task.id!,
      isCompleted: isCompleted,
    );
  }

  void _editTask(Task task) async {
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
      await context.read<TaskProvider>().deleteTask(task.id!);
    }
  }

  Future<void> _permanentlyDeleteTask(Task task, DateTime selectedDate) async {
    final pref = await SharedPreferences.getInstance();
    final user = User.fromJson(jsonDecode(pref.getString('user')!));
    final tasksJson = pref.getString('tasks_${user.id}');
    final selectedDateKey = DataKey.dateKey(selectedDate);

    Map<String, List<String>> tasksMap =
        tasksJson != null
            ? Map<String, List<String>>.from(
              jsonDecode(
                tasksJson,
              ).map((k, v) => MapEntry(k, List<String>.from(v))),
            )
            : {};

    if (!tasksMap.containsKey(selectedDateKey)) {
      return;
    }

    List<String> tasks = tasksMap[selectedDateKey]!;

    bool taskFound = false;
    for (int i = 0; i < tasks.length; i++) {
      Map<String, dynamic> taskJson = jsonDecode(tasks[i]);

      if (taskJson['id'] == task.id) {
        tasks.removeAt(i);
        taskFound = true;
        break;
      }
    }

    if (tasks.isEmpty) {
      tasksMap.remove(selectedDateKey);
    }

    if (taskFound) {
      final updatedTasksJson = jsonEncode(tasksMap);
      await pref.setString('tasks_${user.id}', updatedTasksJson);
      setState(() {
        _tasks =
            tasksMap[selectedDateKey]!
                .map((taskJson) => Task.fromJson(jsonDecode(taskJson)))
                .toList();
      });
    } else {
      print('Task $task.id not found on $selectedDateKey');
    }
  }

  List<Task> get _filteredTasks {
    switch (_selectedFilter) {
      case 'In Progress':
        return _tasks.where((task) => task.isCompleted != true).toList();
      case 'Completed':
        return _tasks.where((task) => task.isCompleted == true).toList();
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    return Scaffold(
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
                  'Tasks',
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
                Text(
                  '${_tasks.length} tasks for ${_getDateLabel()}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: isTablet ? 16 : 14,
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
                  "Today's Progress",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedTasks of $totalTasks completed',
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
                      'High',
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
          // Delete action - show confirmation
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
                () => _toggleTaskCompletion(
                  task,
                  _selectedDate,
                  !task.isCompleted!,
                ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Row(
                children: [
                  _buildCheckboxButton(task, isTablet),
                  SizedBox(width: isTablet ? 16 : 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Priority
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

                        // Description
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

                        // Category and Due Time
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
                  'Delete Task',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  'Are you sure you want to delete "${task.title}"?',
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

  Widget _buildCheckboxButton(Task task, bool isTablet) {
    final size = isTablet ? 28.0 : 24.0;

    return Container(
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
    );
  }

  Widget _buildPriorityChip(Task task, bool isTablet) {
    Color color;
    String label;
    switch (task.priority) {
      case TaskPriority.high:
        color = Colors.red.shade400;
        label = 'HIGH';
        break;
      case TaskPriority.medium:
        color = Colors.orange.shade400;
        label = 'MEDIUM';
        break;
      default:
        color = Colors.green.shade400;
        label = 'LOW';
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
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  int _getHighPriorityCount() =>
      _tasks.where((t) => t.priority == TaskPriority.high).length;
}
