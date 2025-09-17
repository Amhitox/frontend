import 'package:flutter/material.dart';
import 'package:frontend/helpers/cache_manager.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _slideController;
  late AnimationController _breathingController;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.mic,
      title: 'Voice Control',
      subtitle: 'Speak Naturally',
      description:
          'Transform your productivity with intuitive voice commands. Just speak and watch your tasks come to life.',
    ),
    OnboardingPage(
      icon: Icons.analytics_outlined,
      title: 'Smart Insights',
      subtitle: 'Track Progress',
      description:
          'Gain powerful insights into your productivity patterns with beautiful analytics and detailed reports.',
    ),
    OnboardingPage(
      icon: Icons.security_outlined,
      title: 'Privacy First',
      subtitle: 'Stay Protected',
      description:
          'Your data is encrypted and secure. Experience powerful features while maintaining complete privacy.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
    _breathingController.repeat(reverse: true);
    initCache();
  }

  void initCache() async {
    final taskprovider = context.read<TaskProvider>();
    CacheManager(taskprovider).runCacheManager();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Enhanced responsive breakpoints with iPhone 8 specific handling
    final isVerySmallScreen = screenHeight < 680; // iPhone 8 and smaller
    final isSmallScreen = screenHeight < 750 || screenWidth < 400;
    final isMediumScreen = screenHeight >= 700 && screenHeight < 900;
    final isTablet = screenWidth > 600;

    // Theme-aware colors
    final isDark = theme.brightness == Brightness.dark;
    final backgroundGradient =
        isDark
            ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0C1421), // deepDark
                Color(0xFF141D2E), // darkBlue
                Color(0xFF1A2332),
              ],
            )
            : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(
                  0xFF3B77D8,
                ).withValues(alpha: 0.05), // customBlue tint
                const Color(0xFF3B77D8).withValues(alpha: 0.08),
              ],
            );

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF141D2E);
    final secondaryTextColor =
        isDark
            ? Colors.white.withValues(alpha: 0.7)
            : const Color(0xFF141D2E).withValues(alpha: 0.7);
    final subtitleTextColor =
        isDark
            ? Colors.white.withValues(alpha: 0.6)
            : const Color(0xFF141D2E).withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(
                  isVerySmallScreen,
                  isSmallScreen,
                  isTablet,
                  primaryTextColor,
                  isDark,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged:
                        (index) => setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder:
                        (context, index) => _buildPage(
                          _pages[index],
                          index,
                          isVerySmallScreen,
                          isSmallScreen,
                          isMediumScreen,
                          isTablet,
                          primaryTextColor,
                          secondaryTextColor,
                          subtitleTextColor,
                        ),
                  ),
                ),
                _buildBottomSection(
                  isVerySmallScreen,
                  isSmallScreen,
                  isMediumScreen,
                  isTablet,
                  primaryTextColor,
                  secondaryTextColor,
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    bool isVerySmallScreen,
    bool isSmallScreen,
    bool isTablet,
    Color primaryTextColor,
    bool isDark,
  ) {
    final logoSize =
        isVerySmallScreen
            ? 28.0 // Much smaller for iPhone 8
            : isSmallScreen
            ? 36.0
            : isTablet
            ? 44.0
            : 40.0;
    final titleSize =
        isVerySmallScreen
            ? 16.0 // Smaller title for iPhone 8
            : isSmallScreen
            ? 18.0
            : isTablet
            ? 22.0
            : 20.0;
    final skipButtonPadding =
        isVerySmallScreen
            ? 12.0 // Smaller padding for iPhone 8
            : isSmallScreen
            ? 16.0
            : isTablet
            ? 24.0
            : 20.0;

    return Padding(
      padding: EdgeInsets.all(
        isVerySmallScreen
            ? 12.0 // Reduced padding for iPhone 8
            : isSmallScreen
            ? 16.0
            : isTablet
            ? 24.0
            : 20.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Image.asset(
                    'assets/images/logo1.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8), // Reduced spacing
                Text(
                  'Aixy',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: skipButtonPadding,
                vertical:
                    isVerySmallScreen
                        ? 6 // Smaller vertical padding
                        : isSmallScreen
                        ? 8
                        : isTablet
                        ? 12
                        : 10,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFF3B77D8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF3B77D8).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFF3B77D8),
                  fontSize:
                      isVerySmallScreen
                          ? 11 // Even smaller font
                          : isSmallScreen
                          ? 12
                          : isTablet
                          ? 16
                          : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    OnboardingPage page,
    int index,
    bool isVerySmallScreen,
    bool isSmallScreen,
    bool isMediumScreen,
    bool isTablet,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color subtitleTextColor,
  ) {
    // Responsive sizing with iPhone 8 specific adjustments
    final horizontalPadding =
        isVerySmallScreen
            ? 20.0 // Reduced padding for iPhone 8
            : isSmallScreen
            ? 24.0
            : isTablet
            ? 48.0
            : 32.0;
    final baseIconSize =
        isVerySmallScreen
            ? 140.0 // Much smaller icon area for iPhone 8
            : isSmallScreen
            ? 200.0
            : isTablet
            ? 300.0
            : isMediumScreen
            ? 250.0
            : 220.0;
    final iconContainerSize =
        isVerySmallScreen
            ? 80.0 // Smaller container for iPhone 8
            : isSmallScreen
            ? 120.0
            : isTablet
            ? 160.0
            : 140.0;
    final iconSize =
        isVerySmallScreen
            ? 40.0 // Smaller icon for iPhone 8
            : isSmallScreen
            ? 60.0
            : isTablet
            ? 80.0
            : 70.0;
    final titleSize =
        isVerySmallScreen
            ? 22.0 // Smaller title for iPhone 8
            : isSmallScreen
            ? 28.0
            : isTablet
            ? 38.0
            : 32.0;
    final descriptionSize =
        isVerySmallScreen
            ? 13.0 // Smaller description for iPhone 8
            : isSmallScreen
            ? 15.0
            : isTablet
            ? 18.0
            : 16.0;
    final subtitleSize =
        isVerySmallScreen
            ? 10.0 // Smaller subtitle for iPhone 8
            : isSmallScreen
            ? 11.0
            : isTablet
            ? 14.0
            : 12.0;

    return SingleChildScrollView(
      // Added scroll capability
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height * 0.6, // Minimum height
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon section
              TweenAnimationBuilder<double>(
                key: ValueKey(index),
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.7 + (value * 0.3),
                    child: Opacity(
                      opacity: value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Breathing circle - reduced for iPhone 8
                          if (!isVerySmallScreen) // Skip breathing circle on very small screens
                            AnimatedBuilder(
                              animation: _breathingController,
                              builder: (context, child) {
                                return Container(
                                  width:
                                      baseIconSize +
                                      (_breathingController.value * 15),
                                  height:
                                      baseIconSize +
                                      (_breathingController.value * 15),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        primaryTextColor.withValues(
                                          alpha: 0.05,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: primaryTextColor.withValues(
                                        alpha:
                                            0.1 -
                                            (_breathingController.value * 0.03),
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                          // Main icon
                          Container(
                            width: iconContainerSize,
                            height: iconContainerSize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(
                                    0xFF3B77D8,
                                  ).withValues(alpha: 0.15),
                                  const Color(
                                    0xFF3B77D8,
                                  ).withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                iconContainerSize * 0.25,
                              ),
                              border: Border.all(
                                color: const Color(
                                  0xFF3B77D8,
                                ).withValues(alpha: 0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3B77D8,
                                  ).withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              page.icon,
                              size: iconSize,
                              color: const Color(0xFF3B77D8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(
                height:
                    isVerySmallScreen
                        ? 30 // Much smaller spacing for iPhone 8
                        : isSmallScreen
                        ? 50
                        : isTablet
                        ? 70
                        : 60,
              ),

              // Text content
              Text(
                page.subtitle.toUpperCase(),
                style: TextStyle(
                  color: subtitleTextColor,
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing:
                      isVerySmallScreen ? 1.5 : 2, // Reduced letter spacing
                ),
              ),

              SizedBox(
                height:
                    isVerySmallScreen
                        ? 6 // Smaller spacing for iPhone 8
                        : isSmallScreen
                        ? 10
                        : isTablet
                        ? 16
                        : 12,
              ),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500 : double.infinity,
                ),
                child: Text(
                  page.title,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing:
                        isVerySmallScreen ? -0.5 : -1, // Reduced letter spacing
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(
                height:
                    isVerySmallScreen
                        ? 12 // Smaller spacing for iPhone 8
                        : isSmallScreen
                        ? 20
                        : isTablet
                        ? 28
                        : 24,
              ),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 400 : double.infinity,
                ),
                child: Text(
                  page.description,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: descriptionSize,
                    height:
                        isVerySmallScreen ? 1.4 : 1.6, // Reduced line height
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(
    bool isVerySmallScreen,
    bool isSmallScreen,
    bool isMediumScreen,
    bool isTablet,
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final bottomPadding =
        isVerySmallScreen
            ? 16.0 // Reduced padding for iPhone 8
            : isSmallScreen
            ? 24.0
            : isTablet
            ? 40.0
            : 32.0;
    final buttonHeight =
        isVerySmallScreen
            ? 44.0 // Smaller button for iPhone 8
            : isSmallScreen
            ? 52.0
            : isTablet
            ? 60.0
            : 56.0;
    final backButtonHeight =
        isVerySmallScreen
            ? 36.0 // Smaller back button for iPhone 8
            : isSmallScreen
            ? 44.0
            : isTablet
            ? 52.0
            : 48.0;
    final buttonFontSize =
        isVerySmallScreen
            ? 14.0 // Smaller font for iPhone 8
            : isSmallScreen
            ? 15.0
            : isTablet
            ? 18.0
            : 16.0;

    return Padding(
      padding: EdgeInsets.all(bottomPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
        child: Column(
          children: [
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 3 : (isSmallScreen ? 4 : 6),
                  ),
                  width:
                      _currentPage == index
                          ? (isVerySmallScreen
                              ? 24 // Smaller indicator for iPhone 8
                              : isSmallScreen
                              ? 28
                              : isTablet
                              ? 36
                              : 32)
                          : 6, // Smaller inactive indicator
                  height: isVerySmallScreen ? 6 : 8, // Thinner for iPhone 8
                  decoration: BoxDecoration(
                    gradient:
                        _currentPage == index
                            ? LinearGradient(
                              colors: [
                                const Color(0xFF3B77D8),
                                const Color(0xFF3B77D8).withValues(alpha: 0.7),
                              ],
                            )
                            : null,
                    color:
                        _currentPage != index
                            ? primaryTextColor.withValues(alpha: 0.3)
                            : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            SizedBox(
              height:
                  isVerySmallScreen
                      ? 20 // Much smaller spacing for iPhone 8
                      : isSmallScreen
                      ? 32
                      : isTablet
                      ? 48
                      : 40,
            ),

            // Main button
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B77D8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentPage < _pages.length - 1 ? 'Continue' : 'Get Started',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            if (_currentPage > 0) ...[
              SizedBox(
                height:
                    isVerySmallScreen
                        ? 8 // Smaller spacing for iPhone 8
                        : isSmallScreen
                        ? 12
                        : isTablet
                        ? 20
                        : 16,
              ),
              SizedBox(
                width: double.infinity,
                height: backButtonHeight,
                child: TextButton(
                  onPressed:
                      () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
