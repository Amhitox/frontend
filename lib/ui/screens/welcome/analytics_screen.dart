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

  // Enhanced responsive breakpoints for better iPad support
  bool _isLargeScreen(double width) => width >= 1024;
  bool _isTablet(double width) => width >= 768 && width < 1024;
  bool _isSmallTablet(double width) => width >= 600 && width < 768;
  bool _isMobile(double width) => width < 600;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape = screenWidth > screenHeight;

    // Enhanced responsive dimensions
    final double horizontalPadding = _getHorizontalPadding(screenWidth);
    final double verticalSpacing = _getVerticalSpacing(screenWidth);
    final double contentMaxWidth = _getContentMaxWidth(screenWidth);

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
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  children: [
                    _buildHeader(context, screenWidth),
                    _buildPeriodTabs(context, screenWidth),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: _buildResponsiveLayout(
                          context,
                          screenWidth,
                          isLandscape,
                          verticalSpacing,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getHorizontalPadding(double width) {
    if (_isLargeScreen(width)) return 40.0;
    if (_isTablet(width)) return 32.0;
    if (_isSmallTablet(width)) return 24.0;
    return 16.0;
  }

  double _getVerticalSpacing(double width) {
    if (_isLargeScreen(width)) return 28.0;
    if (_isTablet(width)) return 24.0;
    if (_isSmallTablet(width)) return 20.0;
    return 16.0;
  }

  double _getContentMaxWidth(double width) {
    if (_isLargeScreen(width)) return 1400.0;
    if (_isTablet(width)) return double.infinity;
    return double.infinity;
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    double screenWidth,
    bool isLandscape,
    double spacing,
  ) {
    // For iPads and larger screens in landscape, use a sophisticated multi-column layout
    if ((_isTablet(screenWidth) || _isLargeScreen(screenWidth)) &&
        isLandscape) {
      return _buildTabletLandscapeLayout(context, screenWidth, spacing);
    }
    // For iPads in portrait, use a two-column layout for some sections
    else if (_isTablet(screenWidth) || _isLargeScreen(screenWidth)) {
      return _buildTabletPortraitLayout(context, screenWidth, spacing);
    }
    // For smaller tablets, use an optimized single-column layout
    else if (_isSmallTablet(screenWidth)) {
      return _buildSmallTabletLayout(context, screenWidth, spacing);
    }
    // For mobile devices
    else {
      return _buildMobileLayout(context, screenWidth, spacing);
    }
  }

  // Enhanced tablet landscape layout
  Widget _buildTabletLandscapeLayout(
    BuildContext context,
    double screenWidth,
    double spacing,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        // Stats in a single row for landscape
        _buildQuickStats(context, crossAxisCount: 4, aspectRatio: 1.4),
        SizedBox(height: spacing),
        // Main content in three columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Productivity and insights
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildProductivityCard(context, screenWidth),
                  SizedBox(height: spacing),
                  _buildInsightsCard(context, screenWidth),
                ],
              ),
            ),
            SizedBox(width: spacing),
            // Middle column - Chart
            Expanded(flex: 2, child: _buildChartCard(context, screenWidth)),
            SizedBox(width: spacing),
            // Right column - Category breakdown
            Expanded(
              flex: 2,
              child: _buildCategoryBreakdown(context, screenWidth),
            ),
          ],
        ),
        SizedBox(height: spacing * 1.5),
      ],
    );
  }

  // Enhanced tablet portrait layout
  Widget _buildTabletPortraitLayout(
    BuildContext context,
    double screenWidth,
    double spacing,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        _buildQuickStats(context, crossAxisCount: 4, aspectRatio: 1.6),
        SizedBox(height: spacing),
        // Two-column layout for main content
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildProductivityCard(context, screenWidth),
                  SizedBox(height: spacing),
                  _buildChartCard(context, screenWidth),
                ],
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildCategoryBreakdown(context, screenWidth),
                  SizedBox(height: spacing),
                  _buildInsightsCard(context, screenWidth),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 1.5),
      ],
    );
  }

  // Small tablet layout
  Widget _buildSmallTabletLayout(
    BuildContext context,
    double screenWidth,
    double spacing,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        _buildQuickStats(context, crossAxisCount: 2, aspectRatio: 1.8),
        SizedBox(height: spacing),
        _buildProductivityCard(context, screenWidth),
        SizedBox(height: spacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildChartCard(context, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildCategoryBreakdown(context, screenWidth)),
          ],
        ),
        SizedBox(height: spacing),
        _buildInsightsCard(context, screenWidth),
        SizedBox(height: spacing * 1.5),
      ],
    );
  }

  // Mobile layout
  Widget _buildMobileLayout(
    BuildContext context,
    double screenWidth,
    double spacing,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        _buildQuickStats(context, crossAxisCount: 2, aspectRatio: 1.5),
        SizedBox(height: spacing),
        _buildProductivityCard(context, screenWidth),
        SizedBox(height: spacing),
        _buildChartCard(context, screenWidth),
        SizedBox(height: spacing),
        _buildCategoryBreakdown(context, screenWidth),
        SizedBox(height: spacing),
        _buildInsightsCard(context, screenWidth),
        SizedBox(height: spacing * 1.5),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);

    // Enhanced responsive sizing
    final double padding = _getHeaderPadding(screenWidth);
    final double iconSize = _getHeaderIconSize(screenWidth);
    final double titleSize = _getHeaderTitleSize(screenWidth);
    final double subtitleSize = _getHeaderSubtitleSize(screenWidth);
    final double borderRadius = _getHeaderBorderRadius(screenWidth);
    final double margin = _getHeaderMargin(screenWidth);

    return Container(
      margin: EdgeInsets.all(margin),
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
                    SizedBox(height: _isTablet(screenWidth) ? 6 : 4),
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
                  _buildHeaderButton(
                    Icons.download_outlined,
                    () {},
                    screenWidth,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderButton(Icons.share_outlined, () {}, screenWidth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isTablet(screenWidth) ? 20 : 16,
              vertical: _isTablet(screenWidth) ? 16 : 12,
            ),
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
                  screenWidth,
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
                  screenWidth,
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
                  screenWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getHeaderPadding(double width) {
    if (_isLargeScreen(width)) return 32.0;
    if (_isTablet(width)) return 28.0;
    if (_isSmallTablet(width)) return 24.0;
    return 20.0;
  }

  double _getHeaderIconSize(double width) {
    if (_isLargeScreen(width)) return 64.0;
    if (_isTablet(width)) return 60.0;
    if (_isSmallTablet(width)) return 56.0;
    return 48.0;
  }

  double _getHeaderTitleSize(double width) {
    if (_isLargeScreen(width)) return 32.0;
    if (_isTablet(width)) return 28.0;
    if (_isSmallTablet(width)) return 26.0;
    return 22.0;
  }

  double _getHeaderSubtitleSize(double width) {
    if (_isLargeScreen(width)) return 18.0;
    if (_isTablet(width)) return 16.0;
    if (_isSmallTablet(width)) return 15.0;
    return 13.0;
  }

  double _getHeaderBorderRadius(double width) {
    if (_isTablet(width) || _isLargeScreen(width)) return 28.0;
    return 24.0;
  }

  double _getHeaderMargin(double width) {
    if (_isLargeScreen(width)) return 24.0;
    if (_isTablet(width)) return 20.0;
    return 16.0;
  }

  Widget _buildQuickMetric(
    String label,
    String value,
    Color color,
    double screenWidth,
  ) {
    final theme = Theme.of(context);
    final double valueSize = _isTablet(screenWidth) ? 20.0 : 18.0;
    final double labelSize = _isTablet(screenWidth) ? 12.0 : 11.0;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: labelSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(
    IconData icon,
    VoidCallback onTap,
    double screenWidth,
  ) {
    final theme = Theme.of(context);
    final double buttonSize = _isTablet(screenWidth) ? 44.0 : 36.0;
    final double iconSize = _isTablet(screenWidth) ? 20.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: iconSize),
      ),
    );
  }

  Widget _buildPeriodTabs(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final double fontSize = _getTabFontSize(screenWidth);
    final double padding = _getTabPadding(screenWidth);

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
                    padding: EdgeInsets.symmetric(
                      vertical: _isTablet(screenWidth) ? 12 : 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.colorScheme.surface
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getShortPeriodName(period),
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

  double _getTabFontSize(double width) {
    if (_isTablet(width) || _isLargeScreen(width)) return 16.0;
    if (_isSmallTablet(width)) return 14.0;
    return 12.0;
  }

  double _getTabPadding(double width) {
    if (_isLargeScreen(width)) return 32.0;
    if (_isTablet(width)) return 24.0;
    return 16.0;
  }

  String _getShortPeriodName(String period) {
    switch (period) {
      case 'This Week':
        return 'Week';
      case 'This Month':
        return 'Month';
      case 'This Year':
        return 'Year';
      default:
        return period;
    }
  }

  Widget _buildQuickStats(
    BuildContext context, {
    int crossAxisCount = 2,
    double aspectRatio = 1.5,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Better aspect ratio calculation for iPads
    double finalAspectRatio = aspectRatio;
    if (_isTablet(screenWidth) || _isLargeScreen(screenWidth)) {
      finalAspectRatio = crossAxisCount == 4 ? 1.4 : 1.6;
    } else if (_isSmallTablet(screenWidth)) {
      finalAspectRatio = crossAxisCount == 4 ? 1.3 : 1.7;
    }

    // Enhanced spacing for different screen sizes
    final double crossSpacing =
        _isLargeScreen(screenWidth)
            ? 24.0
            : _isTablet(screenWidth)
            ? 20.0
            : _isSmallTablet(screenWidth)
            ? 18.0
            : 16.0;
    final double mainSpacing = crossSpacing;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: finalAspectRatio,
          crossAxisSpacing: crossSpacing,
          mainAxisSpacing: mainSpacing,
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

    // Enhanced responsive sizing
    final double cardPadding = _getStatCardPadding(screenWidth);
    final double iconSize = _getStatCardIconSize(screenWidth);
    final double valueSize = _getStatCardValueSize(screenWidth);
    final double titleSize = _getStatCardTitleSize(screenWidth);
    final double spacing = _getStatCardSpacing(screenWidth);

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available space for better layout distribution
          final availableHeight = constraints.maxHeight - (cardPadding * 2);
          final iconSpace = iconSize + spacing;
          final remainingHeight = availableHeight - iconSpace;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Icon container with fixed size
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(iconSize * 0.25),
                ),
                child: Icon(icon, color: color, size: iconSize * 0.55),
              ),
              SizedBox(height: spacing),

              // Value text with proper space allocation
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 1,
                        maxWidth: constraints.maxWidth - (cardPadding * 2),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: valueSize,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),
              ),

              // Small spacing between value and title
              SizedBox(height: spacing * 0.3),

              // Title text with proper space allocation
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.topLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: titleSize,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _getStatCardPadding(double width) {
    if (_isLargeScreen(width)) return 24.0;
    if (_isTablet(width)) return 20.0;
    if (_isSmallTablet(width)) return 18.0;
    return 16.0;
  }

  double _getStatCardIconSize(double width) {
    if (_isLargeScreen(width)) return 40.0;
    if (_isTablet(width)) return 36.0;
    if (_isSmallTablet(width)) return 32.0;
    return 28.0;
  }

  double _getStatCardValueSize(double width) {
    if (_isLargeScreen(width)) return 28.0;
    if (_isTablet(width)) return 24.0;
    if (_isSmallTablet(width)) return 22.0;
    return 20.0;
  }

  double _getStatCardTitleSize(double width) {
    if (_isLargeScreen(width)) return 15.0;
    if (_isTablet(width)) return 14.0;
    if (_isSmallTablet(width)) return 13.0;
    return 12.0;
  }

  double _getStatCardSpacing(double width) {
    if (_isTablet(width) || _isLargeScreen(width)) return 12.0;
    return 10.0;
  }

  Widget _buildProductivityCard(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final double padding = _getCardPadding(screenWidth);
    final double titleSize = _getCardTitleSize(screenWidth);
    final double subtitleSize = _getCardSubtitleSize(screenWidth);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
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
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isTablet(screenWidth) ? 16 : 12,
                    vertical: _isTablet(screenWidth) ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentData.productivityScore}%',
                    style: TextStyle(
                      color: _getProductivityColor(
                        _currentData.productivityScore,
                      ),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: _isTablet(screenWidth) ? 20 : 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _currentData.productivityScore / 100,
                backgroundColor: theme.colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProductivityColor(_currentData.productivityScore),
                ),
                minHeight: _isTablet(screenWidth) ? 12 : 8,
              ),
            ),
            SizedBox(height: _isTablet(screenWidth) ? 20 : 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: _isTablet(screenWidth) ? 20 : 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Avg Response Time: ${_currentData.responseTime}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: subtitleSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getCardPadding(double width) {
    if (_isLargeScreen(width)) return 28.0;
    if (_isTablet(width)) return 24.0;
    if (_isSmallTablet(width)) return 20.0;
    return 16.0;
  }

  double _getCardTitleSize(double width) {
    if (_isLargeScreen(width)) return 22.0;
    if (_isTablet(width)) return 20.0;
    if (_isSmallTablet(width)) return 18.0;
    return 16.0;
  }

  double _getCardSubtitleSize(double width) {
    if (_isLargeScreen(width)) return 16.0;
    if (_isTablet(width)) return 15.0;
    if (_isSmallTablet(width)) return 14.0;
    return 13.0;
  }

  Color _getProductivityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildChartCard(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final double padding = _getCardPadding(screenWidth);
    final double titleSize = _getCardTitleSize(screenWidth);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Trend',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _isTablet(screenWidth) ? 24 : 20),
            SizedBox(
              height: _getChartHeight(screenWidth),
              child: _buildSimpleChart(_currentData.weeklyData, screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  double _getChartHeight(double width) {
    if (_isLargeScreen(width)) return 160.0;
    if (_isTablet(width)) return 140.0;
    if (_isSmallTablet(width)) return 130.0;
    return 120.0;
  }

  Widget _buildSimpleChart(List<int> data, double screenWidth) {
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final theme = Theme.of(context);
    final double barWidth = _getChartBarWidth(screenWidth);
    final double fontSize = _getChartLabelSize(screenWidth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          data.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            final height = (value / maxValue) * _getChartMaxHeight(screenWidth);

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 800 + (index * 100)),
              tween: Tween(begin: 0.0, end: height),
              builder: (context, animatedHeight, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: barWidth,
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
                        borderRadius: BorderRadius.circular(barWidth * 0.4),
                      ),
                    ),
                    SizedBox(height: _isTablet(screenWidth) ? 10 : 8),
                    Text(
                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                );
              },
            );
          }).toList(),
    );
  }

  double _getChartBarWidth(double width) {
    if (_isLargeScreen(width)) return 28.0;
    if (_isTablet(width)) return 24.0;
    if (_isSmallTablet(width)) return 22.0;
    return 18.0;
  }

  double _getChartMaxHeight(double width) {
    if (_isLargeScreen(width)) return 120.0;
    if (_isTablet(width)) return 100.0;
    if (_isSmallTablet(width)) return 90.0;
    return 80.0;
  }

  double _getChartLabelSize(double width) {
    if (_isTablet(width) || _isLargeScreen(width)) return 12.0;
    return 10.0;
  }

  Widget _buildCategoryBreakdown(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final double padding = _getCardPadding(screenWidth);
    final double titleSize = _getCardTitleSize(screenWidth);
    final double itemSize = _getCategoryItemSize(screenWidth);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _isTablet(screenWidth) ? 24 : 20),
            ...List.generate(_currentData.topCategories.length, (index) {
              final category = _currentData.topCategories[index];
              final percentage = _currentData.categoryData[index];
              final color = _currentData.chartColors[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: _isTablet(screenWidth) ? 20 : 16,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: _getCategoryDotSize(screenWidth),
                              height: _getCategoryDotSize(screenWidth),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(
                                  _getCategoryDotSize(screenWidth) * 0.5,
                                ),
                              ),
                            ),
                            SizedBox(width: _isTablet(screenWidth) ? 16 : 12),
                            Text(
                              category,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: itemSize,
                                fontWeight: FontWeight.w500,
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
                            fontSize: itemSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _isTablet(screenWidth) ? 12 : 8),
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1000 + (index * 200)),
                      tween: Tween(begin: 0.0, end: percentage / 100),
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: theme.colorScheme.surfaceContainer,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: _isTablet(screenWidth) ? 8 : 6,
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

  double _getCategoryItemSize(double width) {
    if (_isLargeScreen(width)) return 16.0;
    if (_isTablet(width)) return 15.0;
    if (_isSmallTablet(width)) return 14.0;
    return 13.0;
  }

  double _getCategoryDotSize(double width) {
    if (_isTablet(width) || _isLargeScreen(width)) return 14.0;
    return 12.0;
  }

  Widget _buildInsightsCard(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final double padding = _getCardPadding(screenWidth);
    final double titleSize = _getCardTitleSize(screenWidth);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.yellow.withValues(alpha: 0.8),
                  size: _isTablet(screenWidth) ? 24 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: _isTablet(screenWidth) ? 20 : 16),
            _buildInsightItem(
              'Peak Activity',
              _getPeakActivityInsight(),
              Icons.trending_up,
              Colors.green,
              screenWidth,
            ),
            SizedBox(height: _isTablet(screenWidth) ? 16 : 12),
            _buildInsightItem(
              'Response Pattern',
              _getResponsePatternInsight(),
              Icons.schedule,
              Colors.blue,
              screenWidth,
            ),
            SizedBox(height: _isTablet(screenWidth) ? 16 : 12),
            _buildInsightItem(
              'Suggestion',
              _getSuggestion(),
              Icons.recommend,
              Colors.orange,
              screenWidth,
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
    double screenWidth,
  ) {
    final theme = Theme.of(context);
    final double iconSize = _getInsightIconSize(screenWidth);
    final double titleSize = _getInsightTitleSize(screenWidth);
    final double descSize = _getInsightDescSize(screenWidth);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: iconSize * 0.6),
        ),
        SizedBox(width: _isTablet(screenWidth) ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: descSize,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getInsightIconSize(double width) {
    if (_isLargeScreen(width)) return 32.0;
    if (_isTablet(width)) return 28.0;
    return 24.0;
  }

  double _getInsightTitleSize(double width) {
    if (_isLargeScreen(width)) return 16.0;
    if (_isTablet(width)) return 15.0;
    if (_isSmallTablet(width)) return 14.0;
    return 13.0;
  }

  double _getInsightDescSize(double width) {
    if (_isLargeScreen(width)) return 14.0;
    if (_isTablet(width)) return 13.0;
    if (_isSmallTablet(width)) return 12.0;
    return 11.0;
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
