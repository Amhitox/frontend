import 'package:flutter/material.dart';
import 'package:frontend/ui/widgets/side_menu.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedPeriod = 'This Week';
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  final Map<String, AnalyticsData> _analyticsData = {
    'Today': AnalyticsData(
      emailsSent: 12,
      emailsReceived: 24,
      tasksCompleted: 8,
      meetingsAttended: 3,
      productivityScore: 85,
      responseTime: '2.3 hours',
      topCategories: ['Work', 'Personal', 'Meetings'],
      categoryData: [65, 25, 10],
      weeklyData: [8, 12, 15, 18, 22, 24, 20],
      chartColors: [Colors.blue, Colors.green, Colors.orange],
    ),
    'This Week': AnalyticsData(
      emailsSent: 89,
      emailsReceived: 156,
      tasksCompleted: 34,
      meetingsAttended: 12,
      productivityScore: 78,
      responseTime: '3.1 hours',
      topCategories: ['Work', 'Personal', 'Meetings'],
      categoryData: [60, 30, 10],
      weeklyData: [45, 52, 48, 65, 72, 68, 89],
      chartColors: [Colors.blue, Colors.green, Colors.orange],
    ),
    'This Month': AnalyticsData(
      emailsSent: 342,
      emailsReceived: 578,
      tasksCompleted: 127,
      meetingsAttended: 45,
      productivityScore: 82,
      responseTime: '2.8 hours',
      topCategories: ['Work', 'Personal', 'Projects'],
      categoryData: [70, 20, 10],
      weeklyData: [120, 145, 165, 180, 195, 210, 225],
      chartColors: [Colors.blue, Colors.green, Colors.purple],
    ),
    'This Year': AnalyticsData(
      emailsSent: 3890,
      emailsReceived: 6234,
      tasksCompleted: 1456,
      meetingsAttended: 234,
      productivityScore: 79,
      responseTime: '3.2 hours',
      topCategories: ['Work', 'Personal', 'Projects'],
      categoryData: [65, 25, 10],
      weeklyData: [300, 450, 520, 680, 750, 820, 890],
      chartColors: [Colors.blue, Colors.green, Colors.purple],
    ),
  };

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
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  AnalyticsData get _currentData => _analyticsData[_selectedPeriod]!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Responsive breakpoints
    final isLargeScreen = screenWidth >= 900;
    final isTablet = screenWidth >= 600;
    final isLandscape = screenWidth > screenHeight;

    // Responsive dimensions
    final horizontalPadding =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 16.0;
    final verticalSpacing =
        isLargeScreen
            ? 24.0
            : isTablet
            ? 20.0
            : 16.0;
    final contentMaxWidth = isLargeScreen ? 1200.0 : double.infinity;

    return Scaffold(
      drawer: const SideMenu(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      children: [
                        _buildHeader(context, isTablet, isLargeScreen),
                        _buildPeriodTabs(context, isTablet),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child:
                                isLargeScreen && !isLandscape
                                    ? _buildDesktopLayout(
                                      context,
                                      verticalSpacing,
                                    )
                                    : _buildMobileLayout(
                                      context,
                                      verticalSpacing,
                                      isTablet,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop layout with side-by-side cards
  Widget _buildDesktopLayout(BuildContext context, double spacing) {
    return Column(
      children: [
        SizedBox(height: spacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildQuickStats(context, crossAxisCount: 4),
                  SizedBox(height: spacing),
                  _buildProductivityCard(context),
                ],
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildChartCard(context),
                  SizedBox(height: spacing),
                  _buildInsightsCard(context),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        _buildCategoryBreakdown(context),
        SizedBox(height: spacing * 1.5),
      ],
    );
  }

  // Mobile/tablet layout with stacked cards
  Widget _buildMobileLayout(
    BuildContext context,
    double spacing,
    bool isTablet,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        _buildQuickStats(context, crossAxisCount: isTablet ? 4 : 2),
        SizedBox(height: spacing),
        _buildProductivityCard(context),
        SizedBox(height: spacing),
        _buildChartCard(context),
        SizedBox(height: spacing),
        _buildCategoryBreakdown(context),
        SizedBox(height: spacing),
        _buildInsightsCard(context),
        SizedBox(height: spacing * 1.5),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet, bool isLargeScreen) {
    final theme = Theme.of(context);

    // Responsive sizing
    final padding =
        isLargeScreen
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0;
    final iconSize =
        isLargeScreen
            ? 56.0
            : isTablet
            ? 52.0
            : 48.0;
    final titleSize =
        isLargeScreen
            ? 26.0
            : isTablet
            ? 24.0
            : 22.0;
    final subtitleSize =
        isLargeScreen
            ? 15.0
            : isTablet
            ? 14.0
            : 13.0;
    final borderRadius = isLargeScreen ? 28.0 : 24.0;
    return Container(
      margin: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainer,
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(iconSize * 0.3),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.onSurface,
                  size: iconSize * 0.5,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics Dashboard',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: isTablet ? 4 : 2),
                    Text(
                      'Track your productivity & performance',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildHeaderButton(Icons.download_outlined, () {}),
                  const SizedBox(width: 8),
                  _buildHeaderButton(Icons.share_outlined, () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.6,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickMetric(
                  'Score',
                  '${_currentData.productivityScore}%',
                  _getProductivityColor(_currentData.productivityScore),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                _buildQuickMetric(
                  'Emails',
                  '${_currentData.emailsSent + _currentData.emailsReceived}',
                  Colors.blue,
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                _buildQuickMetric(
                  'Tasks',
                  '${_currentData.tasksCompleted}',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 16),
      ),
    );
  }

  Widget _buildPeriodTabs(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final fontSize = isTablet ? 14.0 : 12.0;
    final padding = isTablet ? 20.0 : 16.0;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children:
            _periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = period);
                    _fadeController.reset();
                    _fadeController.forward();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.colorScheme.surface
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        period == 'This Week'
                            ? 'Week'
                            : period == 'This Month'
                            ? 'Month'
                            : period == 'This Year'
                            ? 'Year'
                            : period,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          fontSize: fontSize,
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

  Widget _buildQuickStats(BuildContext context, {int crossAxisCount = 2}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: crossAxisCount > 2 ? 1.8 : 1.5,
          crossAxisSpacing: crossAxisCount > 2 ? 16 : 12,
          mainAxisSpacing: crossAxisCount > 2 ? 16 : 12,
          children: [
            _buildStatCard(
              'Emails Sent',
              _currentData.emailsSent.toString(),
              Icons.send,
              Colors.blue,
            ),
            _buildStatCard(
              'Emails Received',
              _currentData.emailsReceived.toString(),
              Icons.inbox,
              Colors.green,
            ),
            _buildStatCard(
              'Tasks Completed',
              _currentData.tasksCompleted.toString(),
              Icons.check_circle,
              Colors.orange,
            ),
            _buildStatCard(
              'Meetings',
              _currentData.meetingsAttended.toString(),
              Icons.event,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final double cardPadding =
        screenWidth >= 900
            ? 20.0
            : screenWidth >= 600
            ? 18.0
            : screenWidth >= 400
            ? 16.0
            : 12.0;

    final double iconSize =
        screenWidth >= 900
            ? 33.0
            : screenWidth >= 600
            ? 31.0
            : screenWidth >= 400
            ? 29.0
            : 24.0;

    final double maxValueSize =
        screenWidth >= 900
            ? 25.0
            : screenWidth >= 600
            ? 23.0
            : screenWidth >= 400
            ? 21.0
            : 18.0;

    final double titleSize =
        screenWidth >= 900
            ? 14.0
            : screenWidth >= 600
            ? 13.0
            : screenWidth >= 400
            ? 12.0
            : 10.0;

    final double spacing = screenWidth >= 600 ? 10.0 : 8.0;
    final double titleSpacing = screenWidth >= 600 ? 6.0 : 4.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: 0,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(iconSize * 0.25),
              ),
              child: Icon(icon, color: color, size: iconSize * 0.55),
            ),
          ),
          SizedBox(height: spacing),

          Flexible(
            flex: 0,
            child: Container(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 1,
                    maxWidth:
                        screenWidth * 0.8, // Prevent taking full screen width
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: maxValueSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: titleSpacing),

          Flexible(
            flex: 0,
            child: Container(
              width: double.infinity,
              child: Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: titleSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityCard(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productivity Score',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentData.productivityScore}%',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _currentData.productivityScore / 100,
                backgroundColor: theme.colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProductivityColor(_currentData.productivityScore),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Avg Response Time: ${_currentData.responseTime}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProductivityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildChartCard(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Trend',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 130,
              child: _buildSimpleChart(_currentData.weeklyData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(List<int> data) {
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          data.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            final height = (value / maxValue) * 100;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 800 + (index * 100)),
              tween: Tween(begin: 0.0, end: height),
              builder: (context, animatedHeight, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: animatedHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.blue.withValues(alpha: 0.8),
                            Colors.blue.withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              },
            );
          }).toList(),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(_currentData.topCategories.length, (index) {
              final category = _currentData.topCategories[index];
              final percentage = _currentData.categoryData[index];
              final color = _currentData.chartColors[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              category,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1000 + (index * 200)),
                      tween: Tween(begin: 0.0, end: percentage / 100),
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: theme.colorScheme.surfaceContainer,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.yellow.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              'Peak Activity',
              _getPeakActivityInsight(),
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Response Pattern',
              _getResponsePatternInsight(),
              Icons.schedule,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Suggestion',
              _getSuggestion(),
              Icons.recommend,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPeakActivityInsight() {
    final data = _currentData.weeklyData;
    final maxIndex = data.indexOf(data.reduce((a, b) => a > b ? a : b));
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return 'Your most productive day was ${days[maxIndex]}';
  }

  String _getResponsePatternInsight() {
    if (_currentData.productivityScore > 80) {
      return 'You maintain excellent response times consistently';
    } else if (_currentData.productivityScore > 60) {
      return 'Your response time could be improved during peak hours';
    } else {
      return 'Consider setting up automated responses for better efficiency';
    }
  }

  String _getSuggestion() {
    if (_currentData.productivityScore > 80) {
      return 'Great work! Consider sharing your productivity tips with your team';
    } else {
      return 'Try time-blocking your calendar to improve focus and productivity';
    }
  }
}

class AnalyticsData {
  final int emailsSent;
  final int emailsReceived;
  final int tasksCompleted;
  final int meetingsAttended;
  final int productivityScore;
  final String responseTime;
  final List<String> topCategories;
  final List<int> categoryData;
  final List<int> weeklyData;
  final List<Color> chartColors;

  AnalyticsData({
    required this.emailsSent,
    required this.emailsReceived,
    required this.tasksCompleted,
    required this.meetingsAttended,
    required this.productivityScore,
    required this.responseTime,
    required this.topCategories,
    required this.categoryData,
    required this.weeklyData,
    required this.chartColors,
  });
}
