import 'package:flutter/material.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isListening = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _breathingController;
  late AnimationController _waveController;
  late AnimationController _subtleController;
  late AnimationController _pulseController;
  late AnimationController _orbitalController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _subtleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _orbitalController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _breathingController.repeat(reverse: true);
    _subtleController.repeat();
    _pulseController.repeat(reverse: true);
    _orbitalController.repeat();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _waveController.dispose();
    _subtleController.dispose();
    _pulseController.dispose();
    _orbitalController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      _waveController.repeat();
    } else {
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: Stack(
          children: [
            // Enhanced background elements
            _buildBackgroundElements(screenSize),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      _buildExecutiveAppBar(isTablet, isLargeScreen),
                      Expanded(
                        child: _buildMainContent(
                          constraints,
                          isTablet,
                          isLargeScreen,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundElements(Size screenSize) {
    return Stack(
      children: [
        // Floating particles with improved distribution
        ...List.generate(
          20,
          (index) => _buildFloatingParticle(index, screenSize),
        ),

        // Orbital elements
        _buildOrbitalElements(screenSize),

        // Ambient glow effects
        _buildAmbientGlow(screenSize),
      ],
    );
  }

  Widget _buildFloatingParticle(int index, Size screenSize) {
    return AnimatedBuilder(
      animation: _subtleController,
      builder: (context, child) {
        final offset = (_subtleController.value + (index * 0.05)) % 1.0;
        final horizontalOffset = math.sin(offset * 2 * math.pi + index) * 50;
        final baseX = (index * 67.0) % screenSize.width;

        return Positioned(
          left: (baseX + horizontalOffset).clamp(0, screenSize.width - 10),
          top: screenSize.height * offset,
          child: Container(
            width: 1.5 + (index % 4) * 0.5,
            height: 1.5 + (index % 4) * 0.5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.05 + (math.sin(offset * math.pi) * 0.05),
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbitalElements(Size screenSize) {
    return AnimatedBuilder(
      animation: _orbitalController,
      builder: (context, child) {
        return Stack(
          children: List.generate(3, (index) {
            final angle =
                (_orbitalController.value * 2 * math.pi) +
                (index * 2 * math.pi / 3);
            final radius = 120.0 + (index * 40);
            final centerX = screenSize.width / 2;
            final centerY = screenSize.height / 2;

            return Positioned(
              left: centerX + math.cos(angle) * radius - 3,
              top: centerY + math.sin(angle) * radius - 3,
              child: Container(
                width: 6.0 - index,
                height: 6.0 - index,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3 - index * 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAmbientGlow(Size screenSize) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Positioned(
          top: screenSize.height * 0.3,
          left: screenSize.width * 0.2,
          child: Container(
            width: screenSize.width * 0.6,
            height: screenSize.height * 0.4,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.05 + (_glowController.value * 0.03),
                  ),
                  Colors.transparent,
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExecutiveAppBar(bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isLargeScreen
            ? 32
            : isTablet
            ? 28
            : 24,
        20,
        isLargeScreen
            ? 32
            : isTablet
            ? 28
            : 24,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMenu(isTablet),
          _buildPremiumBadge(isTablet, isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildMenu(bool isTablet) {
    return GestureDetector(
      onTap: () => _scaffoldKey.currentState?.openDrawer(),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 12 : 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.menu_rounded,
          color: Theme.of(context).colorScheme.onSurface,
          size: isTablet ? 28 : 24,
        ),
      ),
    );
  }

  Widget _buildPremiumBadge(bool isTablet, bool isLargeScreen) {
    return GestureDetector(
      onTap: () => context.pushNamed('subscription'),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal:
                  isLargeScreen
                      ? 18
                      : isTablet
                      ? 16
                      : 14,
              vertical: isTablet ? 10 : 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.8 + (_pulseController.value * 0.2),
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8 + (_pulseController.value * 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.diamond_rounded,
                  color: Colors.white,
                  size: isTablet ? 16 : 14,
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        isLargeScreen
                            ? 13
                            : isTablet
                            ? 12
                            : 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(
    BoxConstraints constraints,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final spacing =
        isLargeScreen
            ? 80.0
            : isTablet
            ? 70.0
            : 60.0;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: spacing * 0.5),
          _buildWelcomeSection(isTablet, isLargeScreen),
          _buildCentralMicrophone(isTablet, isLargeScreen),
          _buildVoiceIndicator(isTablet),
          _buildQuickActions(isTablet, isLargeScreen),
          SizedBox(height: spacing * 0.3),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal:
            isLargeScreen
                ? 60
                : isTablet
                ? 50
                : 40,
      ),
      child: Column(
        children: [
          Text(
            _getGreeting(),
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize:
                  isLargeScreen
                      ? 20
                      : isTablet
                      ? 18
                      : 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6),
          ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.onSurface,
                    Theme.of(context).colorScheme.primary,
                  ],
                ).createShader(bounds),
            child: Text(
              'Amhita Marouane',
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    isLargeScreen
                        ? 28
                        : isTablet
                        ? 26
                        : 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Ready to assist you',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildCentralMicrophone(bool isTablet, bool isLargeScreen) {
    final micSize =
        isLargeScreen
            ? 120.0
            : isTablet
            ? 110.0
            : 100.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Enhanced breathing rings with multiple layers
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outermost ring
                Transform.scale(
                  scale: 1.0 + (_breathingController.value * 0.15),
                  child: Container(
                    width: micSize * 1.8,
                    height: micSize * 1.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.1 - (_breathingController.value * 0.05),
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Middle ring
                Transform.scale(
                  scale: 1.0 + (_breathingController.value * 0.12),
                  child: Container(
                    width: micSize * 1.6,
                    height: micSize * 1.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.15 - (_breathingController.value * 0.07),
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Inner ring
                Transform.scale(
                  scale: 1.0 + (_breathingController.value * 0.08),
                  child: Container(
                    width: micSize * 1.4,
                    height: micSize * 1.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.2 - (_breathingController.value * 0.09),
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Main microphone button with enhanced design
        GestureDetector(
          onTap: _toggleListening,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: micSize,
            height: micSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  _isListening
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      )
                      : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.15),
                          Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.08),
                        ],
                      ),
              border: Border.all(
                color:
                    _isListening
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.25),
                width: _isListening ? 2 : 1.5,
              ),
              boxShadow:
                  _isListening
                      ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
            ),
            child: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              size: isTablet ? 40 : 36,
              color:
                  _isListening
                      ? Colors.white
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceIndicator(bool isTablet) {
    return SizedBox(
      height: isTablet ? 50 : 40,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(9, (index) {
              double height =
                  _isListening
                      ? 4 +
                          math.sin(
                                (_waveController.value * 3 * math.pi) +
                                    (index * 0.5),
                              ) *
                              (isTablet ? 12 : 10)
                      : 3;
              return Container(
                width: isTablet ? 4 : 3,
                height: height.abs(),
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 4 : 3),
                decoration: BoxDecoration(
                  gradient:
                      _isListening
                          ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.9),
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.6),
                            ],
                          )
                          : LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                              Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                            ],
                          ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal:
            isLargeScreen
                ? 60
                : isTablet
                ? 50
                : 40,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'Emails',
            Icons.email_rounded,
            () {
              context.pushNamed('mail');
            }, // Add functionality
            isTablet,
          ),
          _buildActionButton(
            'Calendar',
            Icons.calendar_month_rounded,
            () {
              context.pushNamed('calendar');
            }, // Add functionality
            isTablet,
          ),
          _buildActionButton(
            'Tasks',
            Icons.task_alt_rounded,
            () {
              context.pushNamed('task');
            }, // Add functionality
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: isTablet ? 22 : 20,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: isTablet ? 12 : 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
