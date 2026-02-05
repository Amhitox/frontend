import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/analytic_data.dart';
import 'package:frontend/providers/analytic_provider.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io';
import 'package:frontend/utils/localization.dart';

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
  String _selectedPeriod = 'Today'; // Default matching user request
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
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
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideController.forward();
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticProvider>().fetchAnalytics(_selectedPeriod, forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(double width) => width >= 1024;
  bool _isTablet(double width) => width >= 768 && width < 1024;
  bool _isSmallTablet(double width) => width >= 600 && width < 768;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape = screenWidth > screenHeight;
    final double horizontalPadding = _getHorizontalPadding(screenWidth);
    final double verticalSpacing = _getVerticalSpacing(screenWidth);
    final double contentMaxWidth = _getContentMaxWidth(screenWidth);

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
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
          child: Column(
            children: [
               _buildHeader(context, screenWidth),
               _buildPeriodTabs(context, screenWidth),
               Expanded(
                 child: Consumer<AnalyticProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context).errorLoadingAnalytics,
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                              SizedBox(height: 8),
                              Text(provider.error!),
                              ElevatedButton(
                                onPressed: () {
                                  provider.fetchAnalytics(_selectedPeriod, forceRefresh: true);
                                },
                                child: Text(AppLocalizations.of(context).retry),
                              )
                            ],
                          ),
                        );
                      }

                      final data = provider.getData(_selectedPeriod);
                      if (data == null) {
                        return Center(child: Text(AppLocalizations.of(context).noData));
                      }
                      
                      return RefreshIndicator(
                         onRefresh: () async {
                           await provider.fetchAnalytics(_selectedPeriod, forceRefresh: true);
                         },
                         child: SingleChildScrollView(
                           physics: const AlwaysScrollableScrollPhysics(),
                           padding: EdgeInsets.symmetric(
                             horizontal: horizontalPadding,
                           ),
                           child: SlideTransition(
                             position: _slideAnimation,
                             child: Center(
                               child: ConstrainedBox(
                                 constraints: BoxConstraints(maxWidth: contentMaxWidth),
                                 child: _buildResponsiveLayout(
                                   context,
                                   screenWidth,
                                   isLandscape,
                                   verticalSpacing,
                                   data,
                                 ),
                               ),
                             ),
                           ),
                        ),
                      );
                    },
                 ),
               ),
            ],
          ),
            ),
            const DraggableMenu(),
          ],
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
    AnalyticData data,
  ) {
    if ((_isTablet(screenWidth) || _isLargeScreen(screenWidth)) &&
        isLandscape) {
      return _buildTabletLandscapeLayout(context, screenWidth, spacing, data);
    } else if (_isTablet(screenWidth) || _isLargeScreen(screenWidth)) {
      return _buildTabletPortraitLayout(context, screenWidth, spacing, data);
    } else if (_isSmallTablet(screenWidth)) {
      return _buildSmallTabletLayout(context, screenWidth, spacing, data);
    } else {
      return _buildMobileLayout(context, screenWidth, spacing, data);
    }
  }

  Widget _buildTabletLandscapeLayout(
    BuildContext context,
    double screenWidth,
    double spacing,
    AnalyticData data,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        _buildQuickStats(context, data, crossAxisCount: 4, aspectRatio: 1.4),
        SizedBox(height: spacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildProductivityCard(context, screenWidth, data),
                  SizedBox(height: spacing),
                  _buildInsightsCard(context, screenWidth, data),
                ],
              ),
            ),
            SizedBox(width: spacing),
            Expanded(flex: 2, child: _buildChartCard(context, screenWidth, data)),
          ],
        ),
        SizedBox(height: spacing * 4.0),
      ],
    );
  }

  Widget _buildTabletPortraitLayout(
    BuildContext context,
    double screenWidth,
    double spacing,
    AnalyticData data,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        _buildQuickStats(context, data, crossAxisCount: 4, aspectRatio: 1.6),
        SizedBox(height: spacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildProductivityCard(context, screenWidth, data),
                  SizedBox(height: spacing),
                  _buildChartCard(context, screenWidth, data),
                ],
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildInsightsCard(context, screenWidth, data),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 4.0),
      ],
    );
  }

  Widget _buildSmallTabletLayout(
    BuildContext context,
    double screenWidth,
    double spacing,
    AnalyticData data,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        _buildQuickStats(context, data, crossAxisCount: 2, aspectRatio: 1.8),
        SizedBox(height: spacing),
        _buildProductivityCard(context, screenWidth, data),
        SizedBox(height: spacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildChartCard(context, screenWidth, data)),
            SizedBox(width: spacing)
          ],
        ),
        SizedBox(height: spacing),
        _buildInsightsCard(context, screenWidth, data),
        SizedBox(height: spacing * 4.0),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    double screenWidth,
    double spacing,
    AnalyticData data,
  ) {
    return Column(
      children: [
        SizedBox(height: spacing),
        _buildQuickStats(context, data, crossAxisCount: 2, aspectRatio: 1.5),
        SizedBox(height: spacing),
        _buildProductivityCard(context, screenWidth, data),
        SizedBox(height: spacing),
        _buildChartCard(context, screenWidth, data),
        SizedBox(height: spacing),
        _buildInsightsCard(context, screenWidth, data),
        SizedBox(height: spacing * 4.0),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
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
                      AppLocalizations.of(context).analytics,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: _isTablet(screenWidth) ? 6 : 4),
                    Text(
                      AppLocalizations.of(context).analyticsSubtitle,
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
                    () async {
                      final provider = context.read<AnalyticProvider>();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      
                      final path = await provider.generateAndDownloadReport(_selectedPeriod);
                      
                      if (path != null) {
                        try {
                           // User requested "just save it in download"
                           // We will try to copy the file to the public Downloads directory without a picker.
                           
                           File sourceFile = File(path);
                           String fileName = path.split(Platform.pathSeparator).last;
                           String newPath;

                           if (Platform.isAndroid) {
                              // Attempt to save to /storage/emulated/0/Download
                              newPath = '/storage/emulated/0/Download/$fileName';
                              // Ensure unique name
                              int count = 1;
                              while (await File(newPath).exists()) {
                                newPath = '/storage/emulated/0/Download/${fileName.replaceAll('.pdf', '')}_$count.pdf';
                                count++;
                              }
                              
                              await sourceFile.copy(newPath);
                           } else {
                              // On desktop/other, fallback to file saver or just keep it there if in docs
                              // But user said "just make it save it in download", assuming Android primarily or default folder.
                              // We'll stick to the generated path for non-Android or try FileSaver as fallback strictly for non-Android if needed.
                              // For simplicity on Windows dev environment, we use FileSaver as it's standard there.
                              if (!Platform.isAndroid && !Platform.isIOS) {
                                  final bytes = await sourceFile.readAsBytes();
                                  newPath = await FileSaver.instance.saveFile(
                                      name: fileName.split('.').first,
                                      bytes: bytes,
                                      ext: 'pdf',
                                      mimeType: MimeType.pdf,
                                  );
                              } else {
                                newPath = path;
                              }
                           }
                           
                            
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('${AppLocalizations.of(context).savedTo}: $newPath'),
                                action: SnackBarAction(
                                  label: AppLocalizations.of(context).open,
                                  onPressed: () {
                                    OpenFilex.open(newPath);
                                  },
                                ),
                                duration: const Duration(seconds: 5),
                              ),
                            );

                         } catch (e) {
                           scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('${AppLocalizations.of(context).savedTo}: $path'),
                                action: SnackBarAction(
                                  label: AppLocalizations.of(context).open,
                                  onPressed: () {
                                    OpenFilex.open(path);
                                  },
                                ),
                              ),
                           );
                         }
                       } else {
                         scaffoldMessenger.showSnackBar(
                           SnackBar(content: Text(AppLocalizations.of(context).failedToGenerate)),
                         );
                       }
                    },
                    screenWidth,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderButton(Icons.share_outlined, () async {
                      final provider = context.read<AnalyticProvider>();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      
                      // Check if we have a path stored or generate a new one
                      final path = await provider.generateAndDownloadReport(_selectedPeriod);
                       
                      if (path != null) {
                        await Share.shareXFiles([XFile(path)], text: AppLocalizations.of(context).shareAnalyticsMessage);
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context).failedToGenerateShare)),
                        );
                      }
                  }, screenWidth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<AnalyticProvider>(
            builder: (context, provider, child) {
              final data = provider.getData(_selectedPeriod);
              if (data == null) return SizedBox.shrink();

              return Container(
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
                      AppLocalizations.of(context).score,
                      '${data.productivityScore}%',
                      _getProductivityColor(data.productivityScore),
                      screenWidth,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    _buildQuickMetric(
                      AppLocalizations.of(context).emails,
                      '${data.emailsSent + data.emailsReceived}',
                      Colors.blue,
                      screenWidth,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    _buildQuickMetric(
                      AppLocalizations.of(context).tasks,
                      '${data.tasksCompleted}',
                      Colors.orange,
                      screenWidth,
                    ),
                  ],
                ),
              );
            }
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
                    if (isSelected) return;
                    setState(() => _selectedPeriod = period);
                    context.read<AnalyticProvider>().fetchAnalytics(period);
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
                        _getShortPeriodName(context, period),
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

  String _getShortPeriodName(BuildContext context, String period) {
    switch (period) {
      case 'This Week':
        return AppLocalizations.of(context).week;
      case 'This Month':
        return AppLocalizations.of(context).month;
      case 'This Year':
        return AppLocalizations.of(context).year;
      case 'Today':
         return AppLocalizations.of(context).today;
      default:
        return period;
    }
  }

  Widget _buildQuickStats(
    BuildContext context, 
    AnalyticData data,
    {
    int crossAxisCount = 2,
    double aspectRatio = 1.5,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double finalAspectRatio = aspectRatio;
    if (_isTablet(screenWidth) || _isLargeScreen(screenWidth)) {
      finalAspectRatio = crossAxisCount == 4 ? 1.4 : 1.6;
    } else if (_isSmallTablet(screenWidth)) {
      finalAspectRatio = crossAxisCount == 4 ? 1.3 : 1.7;
    }
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
              AppLocalizations.of(context).emailsSent,
              data.emailsSent.toString(),
              Icons.send,
              Colors.blue,
            ),
            _buildStatCard(
              AppLocalizations.of(context).emailsReceived,
              data.emailsReceived.toString(),
              Icons.inbox,
              Colors.green,
            ),
            _buildStatCard(
              AppLocalizations.of(context).tasksCompleted,
              data.tasksCompleted.toString(),
              Icons.check_circle,
              Colors.orange,
            ),
            _buildStatCard(
              AppLocalizations.of(context).meetings,
              data.meetingsAttended.toString(),
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
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(iconSize * 0.25),
                ),
                child: Icon(icon, color: color, size: iconSize * 0.55),
              ),
              SizedBox(height: spacing),
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
              SizedBox(height: spacing * 0.3),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.topLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

  Widget _buildProductivityCard(BuildContext context, double screenWidth, AnalyticData data) {
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
                  AppLocalizations.of(context).productivityScore,
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
                    '${data.productivityScore}%',
                    style: TextStyle(
                      color: _getProductivityColor(
                        data.productivityScore,
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
                value: data.productivityScore / 100,
                backgroundColor: theme.colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProductivityColor(data.productivityScore),
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
                  '${AppLocalizations.of(context).avgResponseTime}: ${data.responseTime}',
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

  Widget _buildChartCard(BuildContext context, double screenWidth, AnalyticData data) {
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
              AppLocalizations.of(context).activityTrends,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _isTablet(screenWidth) ? 24 : 20),
            SizedBox(
              height: _getChartHeight(screenWidth),
              child: _buildSimpleChart(data.weeklyData, screenWidth),
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

  Widget _buildSimpleChart(List<num> data, double screenWidth) {
    final maxValue = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b).toDouble();
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
            final height = maxValue == 0 ? 0.0 : (value / maxValue) * _getChartMaxHeight(screenWidth);
            final label = index < 7 
                ? [
                    AppLocalizations.of(context).monday.substring(0, 3), 
                    AppLocalizations.of(context).tuesday.substring(0, 3), 
                    AppLocalizations.of(context).wednesday.substring(0, 3), 
                    AppLocalizations.of(context).thursday.substring(0, 3), 
                    AppLocalizations.of(context).friday.substring(0, 3), 
                    AppLocalizations.of(context).saturday.substring(0, 3), 
                    AppLocalizations.of(context).sunday.substring(0, 3)
                  ][index] 
                : '';
                
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 800 + (index * 100)),
              tween: Tween(begin: 0.0, end: height),
              builder: (context, animatedHeight, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: barWidth,
                      height: animatedHeight == 0 ? 2 : animatedHeight, 
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
                      label,
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

  Widget _buildInsightsCard(BuildContext context, double screenWidth, AnalyticData data) {
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
                  AppLocalizations.of(context).keyInsights,
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
              AppLocalizations.of(context).peakActivity,
              _getPeakActivityInsight(context, data),
              Icons.trending_up,
              Colors.green,
              screenWidth,
            ),
            SizedBox(height: _isTablet(screenWidth) ? 16 : 12),
            _buildInsightItem(
              AppLocalizations.of(context).responsePattern,
              _getResponsePatternInsight(context, data),
              Icons.schedule,
              Colors.blue,
              screenWidth,
            ),
            SizedBox(height: _isTablet(screenWidth) ? 16 : 12),
            _buildInsightItem(
              AppLocalizations.of(context).suggestion,
              _getSuggestion(context, data),
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

  String _getPeakActivityInsight(BuildContext context, AnalyticData data) {
    final weeklyData = data.weeklyData;
    if (weeklyData.isEmpty) return AppLocalizations.of(context).noActivityData;
    
    int maxIndex = 0;
    num maxValue = -1;
    for (int i = 0; i < weeklyData.length; i++) {
      if (weeklyData[i] > maxValue) {
        maxValue = weeklyData[i];
        maxIndex = i;
      }
    }
    
    final days = [
      AppLocalizations.of(context).monday,
      AppLocalizations.of(context).tuesday,
      AppLocalizations.of(context).wednesday,
      AppLocalizations.of(context).thursday,
      AppLocalizations.of(context).friday,
      AppLocalizations.of(context).saturday,
      AppLocalizations.of(context).sunday,
    ];
    if (maxIndex < days.length) {
      return '${AppLocalizations.of(context).mostProductiveDay} ${days[maxIndex]}';
    }
    return AppLocalizations.of(context).consistentActivity;
  }

  String _getResponsePatternInsight(BuildContext context, AnalyticData data) {
    if (data.productivityScore > 80) {
      return AppLocalizations.of(context).excellentResponse;
    } else if (data.productivityScore > 60) {
      return AppLocalizations.of(context).improvedResponse;
    } else {
      return AppLocalizations.of(context).automateResponses;
    }
  }

  String _getSuggestion(BuildContext context, AnalyticData data) {
    if (data.productivityScore > 80) {
      return AppLocalizations.of(context).shareTips;
    } else {
      return AppLocalizations.of(context).timeBlocking;
    }
  }
}
