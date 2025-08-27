import 'package:flutter/material.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  late PageController _pageController;
  int selectedPlan =
      1; // 0 = Essential, 1 = Premium (Premium selected by default)

  // New billing toggle state
  bool isAnnual = true; // Annual selected by default for better pricing

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: selectedPlan);

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainAnimationController.forward();
    _floatingController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F23), Color(0xFF000000)],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Elements
            _buildFloatingOrbs(),

            // Main Content
            AnimatedBuilder(
              animation: _mainAnimationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Header (fixed at top)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              24.0,
                              16.0,
                              24.0,
                              8.0,
                            ),
                            child: _buildHeader(),
                          ),

                          // Billing Toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: _buildBillingToggle(),
                          ),

                          // Page indicator
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: _buildPageIndicator(),
                          ),

                          // Plans PageView
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  selectedPlan = index;
                                });
                              },
                              children: [
                                _buildPlanPage(0, true), // Essential
                                _buildPlanPage(1, false), // Premium
                              ],
                            ),
                          ),

                          // Bottom section (fixed at bottom)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20.0,
                              4.0,
                              20.0,
                              8.0,
                            ),
                            child: _buildSubscribeButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.055,
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isAnnual = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color:
                      !isAnnual ? const Color(0xFF667EEA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !isAnnual ? Colors.white : Colors.grey[400],
                    fontSize: 14,
                    fontWeight: !isAnnual ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isAnnual = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color:
                      isAnnual ? const Color(0xFF667EEA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Annual',
                      style: TextStyle(
                        color: isAnnual ? Colors.white : Colors.grey[400],
                        fontSize: 14,
                        fontWeight:
                            isAnnual ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (isAnnual) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Save 20%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIndicatorDot(0),
        const SizedBox(width: 8),
        _buildIndicatorDot(1),
      ],
    );
  }

  Widget _buildIndicatorDot(int index) {
    bool isSelected = selectedPlan == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isSelected ? 24 : 8,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF667EEA) : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.1 +
                  20 * _floatingAnimation.value,
              left: -50 + 30 * _floatingAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667EEA).withValues(alpha: 0.1),
                      const Color(0xFF764BA2).withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.6 -
                  15 * _floatingAnimation.value,
              right: -30 - 20 * _floatingAnimation.value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF093FB).withValues(alpha: 0.1),
                      const Color(0xFFF5576C).withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Compact Title
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                  Color(0xFFF093FB),
                  Color(0xFFF5576C),
                ],
              ).createShader(bounds),
          child: const Text(
            'Choose Your Plan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanPage(int planIndex, bool isEssential) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: _buildPlan(planIndex, isEssential),
    );
  }

  Widget _buildPlan(int planIndex, bool isEssential) {
    bool isSelected = selectedPlan == planIndex;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient:
            isEssential
                ? (isSelected
                    ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D3748), Color(0xFF1A202C)],
                    )
                    : const LinearGradient(
                      colors: [Color(0xFF1A1A24), Color(0xFF151521)],
                    ))
                : (isSelected
                    ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                        Color(0xFFF093FB),
                      ],
                    )
                    : const LinearGradient(
                      colors: [Color(0xFF1A1A24), Color(0xFF151521)],
                    )),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isSelected
                  ? (isEssential
                      ? const Color(0xFF4A5568)
                      : const Color(0xFFF093FB))
                  : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color:
                        isEssential
                            ? const Color(0xFF4A5568).withValues(alpha: 0.4)
                            : const Color(0xFFF093FB).withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                ]
                : null,
      ),
      child: Stack(
        children: [
          // Popular badge for Premium
          if (!isEssential && isSelected)
            Positioned(
              top: -28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7043).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    '⭐ MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

          // Essential badge
          if (isEssential && isSelected)
            Positioned(
              top: -28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4B5563).withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    '💡 STARTER PLAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient:
                          isEssential
                              ? const LinearGradient(
                                colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                              )
                              : const LinearGradient(
                                colors: [Color(0xFFF093FB), Color(0xFFFF7043)],
                              ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isEssential
                                  ? const Color(
                                    0xFF4B5563,
                                  ).withValues(alpha: 0.3)
                                  : const Color(
                                    0xFFF093FB,
                                  ).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      isEssential ? Icons.mic : Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEssential ? 'Essential' : 'Premium',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : Colors.grey[300],
                        ),
                      ),
                      Text(
                        isEssential ? 'Get Started' : 'Full Power',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isEssential
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFFFFA726),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Price with billing logic
              _buildPricing(isEssential, isSelected),
              const SizedBox(height: 24),

              // Features
              ...(_buildFeatures(isEssential, isSelected)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricing(bool isEssential, bool isSelected) {
    // Monthly prices
    int monthlyEssential = 12;
    int monthlyPremium = 25;

    // Annual prices (with discount)
    double annualEssential = 8.33; // $100/year
    double annualPremium = 16.67; // $200/year

    // Calculate savings
    int essentialSavings = ((monthlyEssential * 12) - 100);
    int premiumSavings = ((monthlyPremium * 12) - 200);

    String price;
    String period;
    String? originalPrice;
    String? savings;

    if (isAnnual) {
      price =
          isEssential
              ? '\$${annualEssential.toStringAsFixed(0)}'
              : '\$${annualPremium.toStringAsFixed(0)}';
      period = '/month';
      originalPrice = isEssential ? '\$12' : '\$25';
      savings =
          isEssential
              ? 'Save \$$essentialSavings/year'
              : 'Save \$$premiumSavings/year';
    } else {
      price = isEssential ? '\$12' : '\$25';
      period = '/month';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (originalPrice != null && isAnnual) ...[
              Text(
                originalPrice,
                style: TextStyle(
                  fontSize: 20,
                  color: isSelected ? Colors.white54 : Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
            ],
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : Colors.grey[300],
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.white70 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!isEssential && !isAnnual)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        if (isAnnual) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Billed annually',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : Colors.grey[500],
                ),
              ),
              const Spacer(),
              if (savings != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    savings,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _buildFeatures(bool isEssential, bool isSelected) {
    List<Map<String, dynamic>> features =
        isEssential
            ? [
              {
                'title': 'Send/Reply to Emails by Voice',
                'description': 'Voice command email management',
                'icon': Icons.email_outlined,
              },
              {
                'title': 'Voice Task Creation',
                'description': 'Create tasks with voice commands',
                'icon': Icons.task_alt,
              },
              {
                'title': 'Voice Calendar Events',
                'description': 'Schedule meetings vocally',
                'icon': Icons.calendar_month,
              },
              {
                'title': 'Text Notifications',
                'description': 'Tasks + appointments alerts',
                'icon': Icons.notifications,
              },
              {
                'title': 'Centralized Dashboard',
                'description': 'Emails, tasks, agenda, notes',
                'icon': Icons.dashboard,
              },
              {
                'title': 'Secure Storage (2 GB)',
                'description': 'Protected data storage',
                'icon': Icons.cloud_outlined,
              },
              {
                'title': 'Up to 10 Priority Emails',
                'description': 'Mark important emails',
                'icon': Icons.priority_high,
              },
            ]
            : [
              {
                'title': 'Voice Email Reading + Smart Search',
                'description': 'AI reads emails with intelligent search',
                'icon': Icons.hearing,
              },
              {
                'title': 'Smart Reminders',
                'description': 'Unread emails, overdue tasks, upcoming events',
                'icon': Icons.psychology,
              },
              {
                'title': 'Complete Voice Task Management',
                'description': 'Create, modify, delete tasks by voice',
                'icon': Icons.mic_none,
              },
              {
                'title': 'Interactive Voice Notifications',
                'description': 'Confirm or reschedule meetings vocally',
                'icon': Icons.record_voice_over,
              },
              {
                'title': 'Advanced Voice Commands + Natural AI',
                'description': 'Premium natural language processing',
                'icon': Icons.auto_awesome,
              },
              {
                'title': 'Extended Secure Storage (1 TB)',
                'description': 'Enterprise-grade data storage',
                'icon': Icons.cloud_done,
              },
              {
                'title': 'Hybrid Concierge Service',
                'description': 'AI + human support 24/7',
                'icon': Icons.support_agent,
              },
              {
                'title': 'Up to 20 Priority Emails',
                'description': 'Enhanced priority email management',
                'icon': Icons.star,
              },
            ];

    return features
        .map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : Colors.grey[700]?.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color:
                        isSelected ? const Color(0xFF10B981) : Colors.grey[500],
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature['description']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildSubscribeButton() {
    String planName = selectedPlan == 0 ? 'Essential' : 'Premium';
    String billingPeriod = isAnnual ? 'Annual' : 'Monthly';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 47,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Starting your 7-day free trial of the $planName plan ($billingPeriod billing)!',
                  ),
                  backgroundColor: const Color(0xFF667EEA),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: const Color(0xFF667EEA).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'START ${planName.toUpperCase()} ${isAnnual ? '(ANNUAL)' : '(MONTHLY)'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '7-day free trial • Cancel anytime',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooterText() {
    return Text(
      '7-day free trial • Cancel anytime',
      style: TextStyle(color: Colors.grey[500], fontSize: 12),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSecurityBadges() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildBadge(Icons.security, 'Enterprise Security'),
        _buildBadge(Icons.verified_user, 'GDPR Compliant'),
        _buildBadge(Icons.lock, 'SSL Encrypted'),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[600], size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }
}
