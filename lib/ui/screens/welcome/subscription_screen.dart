import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/sub_provider.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/utils/legal_content.dart';
import 'package:frontend/utils/legal_modal.dart';
import 'package:frontend/utils/localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:frontend/utils/legal_helper.dart'; // Added
import 'cmi_payment_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  int _selectedPlanIndex = 0;
  bool _isAnnual = true; // Default to Annual
  final bool _showPlans = false;
  late AnimationController _animationController;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  bool _isMorocco = false;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    // Default to USD if not checked or null (safe fallback)
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isMorocco != null) {
      _isMorocco = authProvider.isMorocco!;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleCmiPayment(
    double amount,
    String planName,
    String planTier,
    String planPeriod,
    String currency,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pleaseLogInFirst)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final subProvider = context.read<SubProvider>();

      final userInfo = {
        'email': user.email ?? 'user@example.com',
        'firstName': user.firstName ?? 'User',
        'lastName': user.lastName ?? 'Name',
        // Phone number requirement removed as per request
        'phone': '',
      };

      final paymentData = await subProvider.initiateCmiPayment(
        amount: amount,
        userId: user.id!,
        userInfo: userInfo,
        planTier: planTier,
        planPeriod: planPeriod,
        currency: currency,
      );

      if (paymentData != null && mounted) {
        final gatewayUrl = paymentData['url'] as String?;
        final params = Map<String, dynamic>.from(paymentData['params'] ?? {});

        if (gatewayUrl == null || gatewayUrl.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).failedToInitiatePayment,
                ),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    CmiPaymentScreen(gatewayUrl: gatewayUrl, params: params),
          ),
        );

        // Force refresh data regardless of result
        if (mounted) {
          setState(() => _isLoading = true);
          // "Late a bit" - give server a moment to process callback if needed, though usually user closing happens after.
          // But user asked for it.
          await Future.delayed(const Duration(seconds: 2));
          await authProvider.refreshUserProfile();

          final updatedUser = authProvider.user;
          final isPremiumNow =
              updatedUser?.subscriptionTier == 'PREMIUM' ||
              updatedUser?.subscriptionTier == 'PRO_BUSINESS' ||
              updatedUser?.subscriptionTier == 'ESSENTIAL' ||
              updatedUser?.subscriptionTier ==
                  planTier; // Check against requested tier

          if (isPremiumNow && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${AppLocalizations.of(context).paymentSuccessfulWelcome}$planName',
                ),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            context.goNamed('home');
          } else if (mounted) {
            // Optional: Show message if still not premium?
            // User requested "verify if tier is not premium". If not, we might assume failed or cancelled.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).paymentFailedOrCancelled,
                ),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).failedToInitiatePayment,
              ),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getPlanName(String? tier, AppLocalizations loc) {
    if (tier == 'PREMIUM') return loc.premium;
    if (tier == 'PRO_BUSINESS') {
      return loc
          .proBusinessIntl; // Using intl key which usually maps to "Business" or similar
    }
    if (tier == 'ESSENTIAL') return loc.essential;
    return tier ?? '';
  }

  Future<void> _handleCancelSubscription() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.cancelSubscription),
            content: Text(l10n.cancelSubscriptionConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.keepSubscription),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.confirmCancellation),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final subProvider = context.read<SubProvider>();
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.user;

        if (user != null) {
          final success = await subProvider.cancelSubscription(user.id!);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.subscriptionCancelled),
                backgroundColor: Colors.green,
              ),
            );
            await authProvider.refreshUserProfile();
            setState(() {});
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.errorCancellingSubscription),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.errorCancellingSubscription}: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);

    // Define plans dynamically based on localization
    final annualPlans = [
      _PlanData(
        title: loc.premiumYear,
        subtitle: 'Annual',
        price: _isMorocco ? 3499.99 : 849.99,
        priceText: _isMorocco ? "3 499.99" : "849.99",
        period:
            _isMorocco
                ? 'MAD / ${loc.perYear.replaceAll('/', '').trim()}'
                : loc.perYear,
        planTier: 'PREMIUM',
        planPeriod: 'ANNUAL',
        features: [
          loc.commandPerDay,
          loc.tasksLimitPremium,
          loc.meetingsLimitPremium,
          loc.emailsLimitPremium,
          loc.createEmailsVoicePremium,
          '*${loc.smartSummariesEmail}',
          loc.priorityEmailHeader,
          loc.priorityEmailManaged,
          loc.realTimeNotifications,
          loc.aiPoweredSummaries,
          loc.voiceEmailReader,
          loc.aiVoiceReply,
        ],
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: AppTheme.primaryBlue,
        badge: loc.annualSavings,
        isPopular: true,
      ),
      _PlanData(
        title: loc.proBusinessYear,
        subtitle: 'Business Annual',
        price: _isMorocco ? 1879.99 : 379.99,
        priceText: _isMorocco ? "1 879.99" : "379.99",
        period:
            _isMorocco
                ? 'MAD / ${loc.perYear.replaceAll('/', '').trim()}'
                : loc.perYear,
        planTier: 'PRO_BUSINESS',
        planPeriod: 'ANNUAL',
        features: [
          loc.voiceCommandsPerDay,
          loc.tasksLimit,
          loc.meetingsLimit,
          loc.emailsStoTLimit,
          loc.createEmailsVoice,
          loc.smartSummariesEmail,
          loc.priorityEmailHeader,
          loc.priorityEmailStoT,
          loc.realTimeNotifications,
          loc.aiPoweredSummaries,
          loc.voiceEmailReader,
          loc.aiVoiceReply,
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFF8B5CF6),
        badge: loc.bestValue,
      ),
    ];

    final sixMonthPlans = [
      _PlanData(
        title: loc.premiumSixMonths,
        subtitle: 'Semi-Annual',
        price: _isMorocco ? 1899.99 : 499.99,
        priceText: _isMorocco ? "1 899.99" : "499.99",
        period:
            _isMorocco
                ? 'MAD / ${loc.per6Months.replaceAll('/', '').trim()}'
                : loc.per6Months,
        planTier: 'PREMIUM',
        planPeriod: 'SIX_MONTHS',
        features: [
          loc.commandPerDay,
          loc.tasksLimitPremium,
          loc.meetingsLimitPremium,
          loc.emailsLimitPremium,
          loc.createEmailsVoicePremium,
          '*${loc.smartSummariesEmail}',
          loc.priorityEmailHeader,
          loc.priorityEmailManaged,
          loc.realTimeNotifications,
          loc.aiPoweredSummaries,
          loc.voiceEmailReader,
          loc.aiVoiceReply,
        ],
        gradient: const LinearGradient(
          colors: [AppTheme.lightBlue, AppTheme.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: AppTheme.lightBlue,
      ),
      _PlanData(
        title: loc.proBusinessSixMonths,
        subtitle: 'Business Semi-Annual',
        price: _isMorocco ? 949.99 : 199.99,
        priceText: _isMorocco ? "949.99" : "199.99",
        period:
            _isMorocco
                ? 'MAD / ${loc.per6Months.replaceAll('/', '').trim()}'
                : loc.per6Months,
        planTier: 'PRO_BUSINESS',
        planPeriod: 'SIX_MONTHS',
        features: [
          loc.voiceCommandsPerDay,
          loc.tasksLimit,
          loc.meetingsLimit,
          loc.emailsStoTLimit,
          loc.createEmailsVoice,
          loc.smartSummariesEmail,
          loc.priorityEmailHeader,
          loc.priorityEmailStoT,
          loc.realTimeNotifications,
          loc.aiPoweredSummaries,
          loc.voiceEmailReader,
          loc.aiVoiceReply,
        ],
        gradient: const LinearGradient(
          colors: [AppTheme.warningOrange, Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: AppTheme.warningOrange,
      ),
    ];

    final currentPlans = _isAnnual ? annualPlans : sixMonthPlans;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BackgroundPainter())),
          SafeArea(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                      ),
                    )
                    : ((user?.subscriptionStatus == 'ACTIVE' ||
                            user?.subscriptionStatus == 'CANCELLED') &&
                        user?.subscriptionTier != 'FREE_TRIAL' &&
                        !_showPlans &&
                        (user?.currentPeriodEnd == null ||
                            user!.currentPeriodEnd!.isAfter(DateTime.now())))
                    ? _buildActiveSubscriptionView(loc, user!, theme)
                    : Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.cardColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.dividerColor.withOpacity(0.1),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: theme.iconTheme.color,
                                  ),
                                  onPressed: () => context.pop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Title Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                loc.chooseYourPlan,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textTheme.titleLarge?.color,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Toggle Switch
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                theme.brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildToggleOption(
                                title: loc.annual,
                                isSelected: _isAnnual,
                                onTap:
                                    () => setState(() {
                                      _isAnnual = true;
                                      _selectedPlanIndex = 0;
                                      _pageController.jumpToPage(0);
                                    }),
                              ),
                              _buildToggleOption(
                                title: loc.sixMonths,
                                isSelected: !_isAnnual,
                                onTap:
                                    () => setState(() {
                                      _isAnnual = false;
                                      _selectedPlanIndex = 0;
                                      _pageController.jumpToPage(0);
                                    }),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _selectedPlanIndex = index);
                            },
                            itemCount: currentPlans.length,
                            itemBuilder: (context, index) {
                              return FadeTransition(
                                opacity: _animationController,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(0.3 * (index + 1), 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        index * 0.15,
                                        1.0,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                                  child: _buildModernPlanCard(
                                    currentPlans[index],
                                    index == _selectedPlanIndex,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Page Indicator
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24, top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              currentPlans.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _selectedPlanIndex == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      _selectedPlanIndex == index
                                          ? AppTheme.primaryBlue
                                          : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Payment Logos
                        _buildPaymentLogos(),
                        const SizedBox(height: 20),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLogos() {
    final logos = [
      'assets/images/AMEX.png',
      'assets/images/logo_cmi.png',
      'assets/images/MarocPay.png',
      'assets/images/unionpay.png',
      'assets/images/secure_code_logo.png',
      'assets/images/tn_verified_by_visa.png',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children:
            logos
                .map(
                  (asset) => Image.asset(
                    asset,
                    height: 24,
                    errorBuilder: (c, o, s) => const SizedBox.shrink(),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          title,
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.5),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernPlanCard(_PlanData plan, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ), // More room
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color:
                isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: plan.accentColor.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gradient accent on the top
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: 4,
                  child: Container(
                    decoration: BoxDecoration(gradient: plan.gradient),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (plan.badge != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: plan.gradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: plan.accentColor.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      plan.badge!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                Text(
                                  plan.title,
                                  style: TextStyle(
                                    fontSize: 20, // Reduced from 26
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.color,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  plan.subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      _isMorocco ? '' : '\$',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    plan.priceText,
                                    style: TextStyle(
                                      fontSize: 30, // Reduced from 38
                                      fontWeight: FontWeight.w800,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.color,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                plan.period,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Features
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children:
                                plan.features
                                    .map(
                                      (feature) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 18, // Reduced
                                              height: 18,
                                              decoration: BoxDecoration(
                                                gradient: plan.gradient,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: plan.accentColor
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                feature,
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.color,
                                                  fontSize: 13,
                                                  height: 1.4,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Terms Checkbox
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (val) {
                                setState(() {
                                  _acceptedTerms = val ?? false;
                                });
                              },
                              fillColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                        ? plan.accentColor
                                        : Theme.of(
                                          context,
                                        ).dividerColor.withOpacity(0.2),
                              ),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.5),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final content = LegalHelper.getLocalizedContent(
                                  context,
                                  LegalContent.terms,
                                );
                                showLegalModal(
                                  context,
                                  AppLocalizations.of(context).termsOfSales,
                                  content,
                                );
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: AppLocalizations.of(context).iAgreeTo,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          ' ${AppLocalizations.of(context).termsOfSales}',
                                      style: TextStyle(
                                        color: plan.accentColor,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // CTA Button
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: _acceptedTerms ? plan.gradient : null,
                          color:
                              _acceptedTerms
                                  ? null
                                  : Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow:
                              _acceptedTerms
                                  ? [
                                    BoxShadow(
                                      color: plan.accentColor.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                _acceptedTerms
                                    ? () => _handleCmiPayment(
                                      plan.price,
                                      plan.title,
                                      plan.planTier,
                                      plan.planPeriod,
                                      _isMorocco ? 'MAD' : 'USD',
                                    )
                                    : null,
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context).subscribeNow,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      _acceptedTerms
                                          ? Colors.white
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.3),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildActiveSubscriptionView(
    AppLocalizations loc,
    User user,
    ThemeData theme,
  ) {
    final isCanceled = user.subscriptionStatus == 'CANCELLED';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header with Back Button
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => context.go('/'),
                ),
              ),
              Expanded(
                child: Text(
                  loc.subscription,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 40),

          Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCanceled
                        ? Icons.timer_outlined
                        : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                if (isCanceled) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Text(
                      loc.statusCanceled.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  loc.yourCurrentPlan,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getPlanName(user.subscriptionTier, loc),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          if (isCanceled)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                "${loc.subscriptionAccessUntil} ${user.currentPeriodEnd != null ? "${user.currentPeriodEnd!.year}-${user.currentPeriodEnd!.month.toString().padLeft(2, '0')}-${user.currentPeriodEnd!.day.toString().padLeft(2, '0')}" : '-'}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

          _buildDetailRow(
            loc.activePlan,
            _getPlanName(user.subscriptionTier, loc),
          ),
          _buildDetailRow(
            loc.payment,
            user.subscriptionPeriod == 'ANNUAL'
                ? loc.billedAnnually
                : loc.monthly,
          ),
          _buildDetailRow(
            isCanceled ? loc.accessEndsOn : loc.renewsOn,
            user.currentPeriodEnd != null
                ? "${user.currentPeriodEnd!.year}-${user.currentPeriodEnd!.month.toString().padLeft(2, '0')}-${user.currentPeriodEnd!.day.toString().padLeft(2, '0')}"
                : '-',
          ),

          const Spacer(),

          if (!isCanceled) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _handleCancelSubscription,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  loc.cancelSubscription,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(loc.cancelsAtPeriodEnd),
            const SizedBox(height: 16),
            Text(
              loc.cancelsAtPeriodEnd,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PlanData {
  final String title;
  final String subtitle;
  final double price;
  final String priceText;
  final String period;
  final String planTier;
  final String planPeriod;
  final List<String> features;
  final Gradient gradient;
  final Color accentColor;
  final String? badge;
  final bool isPopular;

  _PlanData({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceText,
    required this.period,
    required this.planTier,
    required this.planPeriod,
    required this.features,
    required this.gradient,
    required this.accentColor,
    this.badge,
    this.isPopular = false,
  });
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gradient circles matching app theme
    paint.shader = RadialGradient(
      colors: [AppTheme.primaryBlue.withOpacity(0.12), Colors.transparent],
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.25),
        radius: size.width * 0.6,
      ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.25),
      size.width * 0.6,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [AppTheme.accentBlue.withOpacity(0.08), Colors.transparent],
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.7),
        radius: size.width * 0.5,
      ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
