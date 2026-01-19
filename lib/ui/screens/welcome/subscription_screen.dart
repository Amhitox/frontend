import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:frontend/providers/sub_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/ui/widgets/glass_card.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/utils/localization.dart';
import 'package:intl/intl.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});
  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;
  bool _isLoading = false;
  bool isAnnual = true;
  int selectedPlan = 1;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _pageController = PageController(initialPage: 1);
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subProvider = context.read<SubProvider>();
      subProvider.fetchSubscription();
      subProvider.fetchUserCountryAndCurrency();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _getPriceId() {
    if (selectedPlan == 0) {
      return isAnnual
          ? "price_1Sl7EyJJEPfcVvaOk6Sn3n4w"
          : "price_1Sl7IPJJEPfcVvaOk45LjIzY";
    } else if (selectedPlan == 1) {
      return isAnnual
          ? "price_1Sl7OqJJEPfcVvaOW5i3pGhN"
          : "price_1Sl7NVJJEPfcVvaOi3w0QHaE";
    } else {
      // Test Plan
      return "price_1SorcmJJEPfcVvaOpaYK4etk";
    }
  }

  Future<void> _handleSubscription() async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });
    try {
      final priceId = _getPriceId();
      final response = await context.read<SubProvider>().startSubscription(
            priceId,
          );

      if (response?.statusCode != 200) {
        _showError(response?.data['error'] ?? loc.subscriptionFailed);
        return;
      }

      final data = response.data;

      if (data['status'] == 'active' &&
          data['payment_intent_client_secret'] == null &&
          data['setup_intent_client_secret'] == null) {
        _showSuccess(loc.subscriptionSuccess);
        if (mounted) context.pushNamed('home');
        return;
      }

      final paymentIntent = data['payment_intent_client_secret'];
      final setupIntent = data['setup_intent_client_secret'];
      final ephemeralKey = data['ephemeral_key'];
      final customerId = data['customer_id'];
      final subscriptionId = data['subscription_id'];

      String? pSecret = paymentIntent;
      String? sSecret;

      if (pSecret == null) {
        sSecret = setupIntent;
      }

      if (pSecret == null && sSecret == null) {
        _showSuccess(loc.subscriptionSuccess);
        if (mounted) context.pushNamed('home');
        return;
      }

      final pref = await SharedPreferences.getInstance();
      final userStr = pref.getString('user');
      String? userEmail;
      String? userName;
      if (userStr != null) {
        final user = jsonDecode(userStr);
        userEmail = user['email'];
        userName = user['name'];
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          merchantDisplayName: 'Elyo AI',
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          paymentIntentClientSecret: pSecret,
          setupIntentClientSecret: sSecret,
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6C63FF),
              background: Color(0xFF1E1E2C),
              componentBackground: Color(0xFF2D2D44),
              componentBorder: Color(0xFF33334D),
              componentDivider: Color(0xFF33334D),
              primaryText: Colors.white,
              secondaryText: Colors.grey,
              icon: Colors.white,
              placeholderText: Colors.white54,
            ),
            shapes: const PaymentSheetShape(
              borderRadius: 12.0,
              borderWidth: 0.5,
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF6C63FF),
                  text: Colors.white,
                  border: Colors.transparent,
                ),
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF6C63FF),
                  text: Colors.white,
                  border: Colors.transparent,
                ),
              ),
              shapes: const PaymentSheetPrimaryButtonShape(),
            ),
          ),
          billingDetails: (userEmail != null)
              ? BillingDetails(
                  email: userEmail,
                  name: userName,
                )
              : null,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        final confirmResponse =
            await context.read<SubProvider>().confirmSubscription(
                  subscriptionId,
                  customerId,
                );

        if (confirmResponse?.statusCode == 200) {
          // 1. Refresh user profile (might be slightly stale if webhook is slow)
          final authProvider = context.read<AuthProvider>();
          await authProvider.refreshUserProfile();
          
          // 2. FORCE optimistic update to ensure immediate access
          String newTier = 'PREMIUM';
          if (selectedPlan == 0) {
            newTier = 'PRO_BUSINESS';
          } else if (selectedPlan == 2) {
            // Test plan -> Assign Daily Test
            newTier = 'DAILY_TEST';
          }
          
          if (authProvider.user != null) {
             final updatedUser = authProvider.user!.copyWith(
               status: 'active',
               subscriptionStatus: 'active',
               subscriptionTier: newTier,
             );
             await authProvider.updateUserInSession(updatedUser);
          }

          _showSuccess(loc.subscriptionSuccess);
          if (mounted) context.goNamed('home');
        } else {
          _showError(confirmResponse?.data['error'] ?? loc.subscriptionFailed);
        }
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        _showError(loc.paymentCanceled);
      } else {
        _showError('${loc.paymentFailed}: ${e.error.message}');
      }
    } catch (e) {
      _showError('${loc.subscriptionFailed}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCancel() async {
    final subProvider = context.read<SubProvider>();
    final subscriptionId = subProvider.subscription?.subscriptionId;
    final loc = AppLocalizations.of(context)!;

    if (subscriptionId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBlue,
        title: Text(loc.confirmCancelTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(
          loc.confirmCancelDesc,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.keepSubscription,
                style: const TextStyle(color: AppTheme.primaryBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: Text(loc.yesCancel),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await subProvider.cancelSubscription(subscriptionId);
      if (response?.statusCode == 200) {
        _showSuccess(loc.subscriptionWillBeCanceled);
      } else {
        _showError(loc.failedToCancelSubscription);
      }
    } catch (e) {
      _showError('${loc.error}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isSmallScreen = screenHeight < 700;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 36,
        leading: IconButton(
          iconSize: 20,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('home');
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.deepDark,
              AppTheme.darkBlue,
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48.0 : 24.0,
                    vertical: isSmallScreen ? 2.0 : 4.0,
                  ),
                  child: Column(
                    children: [
                      Text(
                        loc.chooseYourPlan,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 1 : 2),
                      if (!_isSubscriber(context))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: _buildBillingToggle(isSmallScreen),
                        ),
                    ],
                  ),
                ),
                if (!_isSubscriber(context)) ...[
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPageDot(0),
                      const SizedBox(width: 6),
                      _buildPageDot(1),
                      const SizedBox(width: 6),
                      _buildPageDot(2),
                    ],
                  ),
                ],
                SizedBox(height: isSmallScreen ? 4 : 8),
                Expanded(
                  child: _isSubscriber(context)
                      ? _buildActivePlanView(isTablet, isSmallScreen)
                      : PageView(
                          controller: _pageController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (page) {
                            setState(() {
                              currentPage = page;
                              selectedPlan = page;
                            });
                          },
                          children: [
                            _buildPlanPage(true, isTablet, isSmallScreen),
                            _buildPlanPage(false, isTablet, isSmallScreen),
                            _buildTestPlanPage(isTablet, isSmallScreen),
                          ],
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48.0 : 24.0,
                    isSmallScreen ? 4.0 : 8.0,
                    isTablet ? 48.0 : 24.0,
                    isSmallScreen ? 8.0 : 12.0,
                  ),
                  child: _buildActionButtons(isSmallScreen),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageDot(int index) {
    bool isActive = currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryBlue : Colors.grey[700],
        borderRadius: BorderRadius.circular(3),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                  blurRadius: 4,
                )
              ]
            : null,
      ),
    );
  }

  Widget _buildBillingToggle(bool isSmallScreen) {
    final loc = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 20,
      opacity: 0.1,
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isAnnual = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isSmallScreen ? 32 : 36,
                decoration: BoxDecoration(
                  color: !isAnnual
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    loc.sixMonths,
                    style: TextStyle(
                      color: !isAnnual ? Colors.white : Colors.grey[400],
                      fontWeight:
                          !isAnnual ? FontWeight.bold : FontWeight.w500,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isAnnual = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isSmallScreen ? 32 : 36,
                decoration: BoxDecoration(
                  color: isAnnual
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.annual,
                        style: TextStyle(
                          color: isAnnual ? Colors.white : Colors.grey[400],
                          fontWeight:
                              isAnnual ? FontWeight.bold : FontWeight.w500,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                      if (isAnnual) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            loc.save20,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 8 : 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPage(bool isProBusiness, bool isTablet, bool isSmallScreen) {
    final sixMonthPrice = isProBusiness ? 199.99 : 499.99;
    final annualPrice = isProBusiness ? 379.99 : 849.99;
    final basePrice = isAnnual ? annualPrice : sixMonthPrice;
    
    final subProvider = context.watch<SubProvider>();
    final displayPrice = subProvider.getDisplayPrice(basePrice);
    
    final loc = AppLocalizations.of(context)!;

    final subscription = context.watch<SubProvider>().subscription;
    final isActive = subscription?.currentPriceId ==
            _getPriceIdForPlan(isProBusiness, isAnnual) &&
        subscription?.status == 'active';

    final Color planColor =
        isProBusiness ? AppTheme.primaryBlue : const Color(0xFFFFD700);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 60.0 : 20.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: planColor.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: GlassCard(
          borderRadius: 20,
          opacity: 0.1,
          color: isActive ? planColor.withOpacity(0.1) : Colors.black,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? planColor.withOpacity(0.6)
                    : Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: planColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isProBusiness ? Icons.business : Icons.auto_awesome,
                        color: planColor,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isProBusiness
                                ? loc.proBusinessIntl
                                : loc.premiumIntl,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          if (!isProBusiness) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.amber.withOpacity(0.5)),
                              ),
                              child: Text(
                                loc.popular,
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: isSmallScreen ? 8 : 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          displayPrice,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isAnnual ? loc.perYear : loc.per6Months,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                SizedBox(height: isSmallScreen ? 16 : 20),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Text(
                      loc.activePlan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (isActive && subscription?.currentPeriodEnd != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: Text(
                        "${loc.renewsOn} ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(subscription!.currentPeriodEnd!)}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                Text(
                  loc.whatsIncluded,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                ..._getFeatures(isProBusiness).map(
                  (feature) => Padding(
                    padding: EdgeInsets.only(
                      bottom: isSmallScreen ? 8 : 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: isSmallScreen ? 12 : 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestPlanPage(bool isTablet, bool isSmallScreen) {
    const price = 1.00;
    final subProvider = context.watch<SubProvider>();
    final displayPrice = subProvider.getDisplayPrice(price);
    final loc = AppLocalizations.of(context)!;

    final subscription = context.watch<SubProvider>().subscription;
    final isActive = subscription?.currentPriceId == "price_1SorcmJJEPfcVvaOpaYK4etk" &&
        subscription?.status == 'active';

    const Color planColor = Colors.purpleAccent;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 60.0 : 20.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: planColor.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: GlassCard(
          borderRadius: 20,
          opacity: 0.1,
          color: isActive ? planColor.withOpacity(0.1) : Colors.black,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? planColor.withOpacity(0.6)
                    : Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: planColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bug_report,
                        color: planColor,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Daily Test Plan",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.purple.withOpacity(0.5)),
                            ),
                            child: Text(
                              "Daily Resub Test",
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: isSmallScreen ? 8 : 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          displayPrice,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "/ day",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.grey[400],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                SizedBox(height: isSmallScreen ? 16 : 20),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Text(
                      loc.activePlan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (isActive && subscription?.currentPeriodEnd != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: Text(
                        "${loc.renewsOn} ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(subscription!.currentPeriodEnd!)}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                Text(
                  "Features",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: isSmallScreen ? 8 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "1 Task / Day\n1 Event / Day\n1 Voice Email / Day",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: isSmallScreen ? 12 : 13,
                            height: 1.3,
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

  String _getPriceIdForPlan(bool isProBusiness, bool isAnnual) {
    if (isProBusiness) {
      return isAnnual
          ? "price_1Sl7EyJJEPfcVvaOk6Sn3n4w"
          : "price_1Sl7IPJJEPfcVvaOk45LjIzY";
    } else {
      return isAnnual
          ? "price_1Sl7OqJJEPfcVvaOW5i3pGhN"
          : "price_1Sl7NVJJEPfcVvaOi3w0QHaE";
    }
  }

  List<String> _getFeatures(bool isProBusiness) {
    final loc = AppLocalizations.of(context)!;
    if (isProBusiness) {
      return [
        loc.voiceCommandsPerDay,
        "20 ${loc.tasksLimit}",
        "20 ${loc.meetingsLimit}",
        "30 ${loc.emailsStoTLimit}",
        loc.createEmailsVoice,
        loc.smartSummariesEmail,
        loc.priorityEmailHeader,
        "30 ${loc.priorityEmailStoT}",
        loc.realTimeNotifications,
        loc.aiPoweredSummaries,
        loc.voiceEmailReader,
        loc.aiVoiceReply,
      ];
    } else {
      return [
        loc.commandPerDay,
        "30 ${loc.tasksLimit}",
        "50 ${loc.meetingsLimit}",
        "100 ${loc.emails}",
        loc.createEmailsVoice,
        loc.smartSummariesEmail,
        loc.priorityEmailHeader,
        "50 ${loc.priorityEmailManaged}",
        loc.realTimeNotifications,
        loc.aiPoweredSummaries,
        loc.voiceEmailReader,
        loc.aiVoiceReply,
      ];
    }
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    final subProvider = context.watch<SubProvider>();
    final subscription = subProvider.subscription;
    final String currentPriceId = _getPriceId();
    final loc = AppLocalizations.of(context)!;

    final isSubscriber = _isSubscriber(context);
    final isActive = isSubscriber || (subscription?.currentPriceId == currentPriceId &&
        subscription?.status == 'active');
    final isCanceling = subscription?.cancelAtPeriodEnd == true;

    String planName;
    if (selectedPlan == 0) {
      planName = loc.proBusinessIntl.replaceAll('\n', ' ');
    } else if (selectedPlan == 1) {
      planName = loc.premiumIntl.replaceAll('\n', ' ');
    } else {
      planName = "Daily Resub Test";
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 44 : 48,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? Colors.grey.withOpacity(0.1)
                      : AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: (_isLoading || isActive) ? null : _handleSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.grey[800] : AppTheme.primaryBlue,
                foregroundColor: isActive ? Colors.white : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: isSmallScreen ? 18 : 20,
                      height: isSmallScreen ? 18 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isActive ? Colors.white : Colors.white,
                      ),
                    )
                  : Text(
                      isActive
                          ? loc.currentPlanAction
                          : '${loc.startPlan} $planName',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 10 : 12),
        if (isActive && !isCanceling)
          TextButton(
            onPressed: _isLoading ? null : _handleCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(loc.cancelSubscription,
                style: TextStyle(
                    color: AppTheme.errorRed.withOpacity(0.8), fontSize: 13)),
          )
        else if (isCanceling)
          Text(
            loc.cancelsAtPeriodEnd,
            style: TextStyle(
              color: Colors.amber,
              fontSize: isSmallScreen ? 12 : 13,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  bool _isSubscriber(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return false;
    // Trust provided AuthProvider.isPremium or check tier directly
    final tier = user.subscriptionTier;
    return tier == 'PREMIUM' || tier == 'PRO_BUSINESS' || tier == 'DAILY_TEST';
  }

  Widget _buildActivePlanView(bool isTablet, bool isSmallScreen) {
    // Determine which plan to show based on user's tier
    final user = context.watch<AuthProvider>().user;
    final tier = user?.subscriptionTier;
    
    if (tier == 'PRO_BUSINESS') {
      return _buildPlanPage(true, isTablet, isSmallScreen);
    } else if (tier == 'PREMIUM') {
      return _buildPlanPage(false, isTablet, isSmallScreen);
    } else if (tier == 'DAILY_TEST') {
       return _buildTestPlanPage(isTablet, isSmallScreen);
    } else {
      // Fallback or Test Plan - if active but unknown tier, defaulting to Premium or Test Page suitable for debug
      // If we are strictly PRO_BUSINESS or PREMIUM, this might catch 'active' generic status if any.
      // For now, let's map unknown to Premium page or Test page? 
      // User said "show current tier". If unknown, showing Test Plan page (which says DEBUG ONLY) is safe/obvious.
      return _buildTestPlanPage(isTablet, isSmallScreen);
    }
  }
}
