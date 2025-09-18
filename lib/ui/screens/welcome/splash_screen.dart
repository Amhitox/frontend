import 'package:flutter/material.dart';
import 'package:frontend/helpers/cache_manager.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _breathingController;
  late AnimationController _particleController;
  late AnimationController _fadeController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    _logoController.forward();
    _particleController.repeat();

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      _breathingController.repeat(reverse: true);
    }

    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      _fadeController.forward().then((_) {
        if (mounted) {
          _navigateNext();
        }
      });
    }
  }

  void _navigateNext() async {
    final auth = context.read<AuthProvider>();
    final pref = await SharedPreferences.getInstance();
    final firstOpen = pref.getBool("firstOpen") ?? true;
    print('firstOpen: $firstOpen');

    if (firstOpen) {
      if (mounted) {
        context.go('/onboarding');
      }
    } else {
      if (auth.isLoggedIn) {
        print(pref.getBool('mustSync'));
        // await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) {
          context.go('/');
        }
      } else {
        if (mounted) {
          context.go('/login');
        }
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _breathingController.dispose();
    _particleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('SplashScreen: Building splash screen');

    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Responsive breakpoints
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    final isMediumScreen = screenHeight >= 700 && screenHeight < 900;

    // Dynamic sizing based on screen size
    final logoSize =
        isSmallScreen
            ? 100.0
            : isMediumScreen
            ? 120.0
            : 140.0;
    final breathingRing1 =
        isSmallScreen
            ? 160.0
            : isMediumScreen
            ? 200.0
            : 220.0;
    final breathingRing2 =
        isSmallScreen
            ? 200.0
            : isMediumScreen
            ? 240.0
            : 260.0;
    final titleSize =
        isSmallScreen
            ? 28.0
            : isMediumScreen
            ? 36.0
            : 42.0;
    final subtitleSize =
        isSmallScreen
            ? 14.0
            : isMediumScreen
            ? 16.0
            : 18.0;

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
                const Color(0xFF3B77D8).withValues(alpha: 0.1),
              ],
            );

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF141D2E);
    final secondaryTextColor =
        isDark
            ? Colors.white.withValues(alpha: 0.7)
            : const Color(0xFF141D2E).withValues(alpha: 0.7);
    final particleColor =
        isDark
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFF3B77D8).withValues(alpha: 0.1);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating particles
              ...List.generate(
                screenWidth > 600
                    ? 20
                    : 15, // Fewer particles on smaller screens
                (index) => _buildFloatingParticle(index, particleColor),
              ),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: Tween<double>(
                    begin: 1.0,
                    end: 0.0,
                  ).animate(_fadeController),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            screenHeight -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo section
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _logoController,
                                  _breathingController,
                                ]),
                                builder: (context, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Breathing rings
                                      Transform.scale(
                                        scale:
                                            1.0 +
                                            (_breathingController.value * 0.1),
                                        child: Container(
                                          width: breathingRing1,
                                          height: breathingRing1,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: primaryTextColor
                                                  .withValues(
                                                    alpha:
                                                        0.1 -
                                                        (_breathingController
                                                                .value *
                                                            0.05),
                                                  ),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Transform.scale(
                                        scale:
                                            1.0 +
                                            (_breathingController.value * 0.15),
                                        child: Container(
                                          width: breathingRing2,
                                          height: breathingRing2,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: primaryTextColor
                                                  .withValues(
                                                    alpha:
                                                        0.08 -
                                                        (_breathingController
                                                                .value *
                                                            0.03),
                                                  ),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Main logo
                                      Transform.scale(
                                        scale: _logoScale.value,
                                        child: Opacity(
                                          opacity: _logoOpacity.value,
                                          child: Image.asset(
                                            'assets/images/logo1.png',
                                            width: logoSize * 1.2,
                                            height: logoSize * 1.2,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              SizedBox(
                                height:
                                    isSmallScreen
                                        ? 30
                                        : isMediumScreen
                                        ? 40
                                        : 50,
                              ),

                              // App name and tagline
                              SlideTransition(
                                position: _textSlide,
                                child: FadeTransition(
                                  opacity: _textOpacity,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Aixy',
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 6 : 8),
                                      Text(
                                        'Where your ideas become reality',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: subtitleSize,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(
                                height:
                                    isSmallScreen
                                        ? 60
                                        : isMediumScreen
                                        ? 80
                                        : 100,
                              ),

                              // Loading indicator
                              FadeTransition(
                                opacity: _textOpacity,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width:
                                          isSmallScreen
                                              ? 60
                                              : isMediumScreen
                                              ? 80
                                              : 100,
                                      child: LinearProgressIndicator(
                                        backgroundColor: primaryTextColor
                                            .withValues(alpha: 0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              const Color(
                                                0xFF3B77D8,
                                              ).withValues(alpha: 0.8),
                                            ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 12 : 16),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: secondaryTextColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: isSmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.w400,
                                      ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index, Color particleColor) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final offset = (_particleController.value + (index * 0.1)) % 1.0;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        final x =
            (math.sin(offset * 2 * math.pi + index) * 50) +
            ((index * 80.0) % screenWidth);
        final y = screenHeight * offset;

        final particleSize = 2.0 + (index % 4);
        final opacity = 0.1 + (index % 3) * 0.05;

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              color: particleColor.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: particleColor.withValues(alpha: opacity * 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
