import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:frontend/providers/sub_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  }
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  Future<void> _handleSubscription() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await context.read<SubProvider>().startSubscription(
        "price_1S5SEtBRjJ0iyFv4sOXXH5KB",
      );
      final paymentIntentClientSecret =
          response.data['payment_intent_client_secret'] as String?;
      final setupIntentClientSecret =
          response.data['setup_intent_client_secret'] as String?;
      final ephemeralKey = response.data['ephemeral_key'] as String;
      final customerId = response.data['customer_id'] as String;
      final subscriptionStatus = response.data['status'] as String;
      final subscriptionId = response.data['subscription_id'] as String;
      if (paymentIntentClientSecret != null) {
        await _initAndPresentPaymentSheet(
          paymentIntentClientSecret,
          null,
          ephemeralKey,
          customerId,
          subscriptionId,
        );
      } else if (subscriptionStatus == 'incomplete' &&
          setupIntentClientSecret != null) {
        await _initAndPresentPaymentSheet(
          null,
          setupIntentClientSecret,
          ephemeralKey,
          customerId,
          subscriptionId,
        );
      } else if (subscriptionStatus == 'active' ||
          subscriptionStatus == 'trialing') {
        _showSuccess('Subscription is active!');
        if (mounted) context.goNamed('home');
      } else {
        _showError('Could not initialize payment. Please try again.');
      }
    } catch (e) {
      _showError('Subscription failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  Future<void> _initAndPresentPaymentSheet(
    String? paymentIntentClientSecret,
    String? setupIntentClientSecret,
    String ephemeralKey,
    String customerId,
    String subscriptionId,
  ) async {
    try {
      await _initPaymentSheet(
        paymentIntentClientSecret,
        setupIntentClientSecret,
        ephemeralKey,
        customerId,
      );
      await Stripe.instance.presentPaymentSheet();
      if (mounted) {
        await context.read<SubProvider>().confirmSubscription(
          subscriptionId,
          customerId,
        );
      }
      _showSuccess('Success! Your subscription is active.');
      if (mounted) {
        context.goNamed('home');
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        _showError('Payment process was canceled.');
      } else {
        _showError('Payment failed: ${e.error.message}');
      }
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    }
  }
  Future<void> _initPaymentSheet(
    String? paymentIntentClientSecret,
    String? setupIntentClientSecret,
    String ephemeralKey,
    String customerId,
  ) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final user = jsonDecode(pref.getString('user')!);
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          setupIntentClientSecret: setupIntentClientSecret,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customerId,
          merchantDisplayName: 'A I X Y',
          style: ThemeMode.system,
          billingDetails: BillingDetails(
            email: user['email'],
            name: user['name'],
          ),
        ),
      );
    } catch (e) {
      throw Exception("Failed to initialize payment sheet: $e");
    }
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isSmallScreen = screenHeight < 700;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 36, 
        leading: IconButton(
          iconSize: 20, 
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 48.0 : 24.0,
                  vertical:
                      isSmallScreen ? 4.0 : 8.0, 
                ),
                child: Column(
                  children: [
                    Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 28, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4), 
                    Text(
                      'Upgrade your voice productivity experience',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 15, 
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16), 
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 100.0 : 24.0,
                ),
                child: _buildBillingToggle(isSmallScreen),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12), 
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageDot(0),
                  const SizedBox(width: 6), 
                  _buildPageDot(1),
                ],
              ),
              SizedBox(height: isSmallScreen ? 6 : 10), 
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      currentPage = page;
                      selectedPlan = page;
                    });
                  },
                  children: [
                    _buildPlanPage(true, isTablet, isSmallScreen), 
                    _buildPlanPage(false, isTablet, isSmallScreen), 
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 48.0 : 24.0,
                  isSmallScreen ? 8.0 : 12.0, 
                  isTablet ? 48.0 : 24.0,
                  isSmallScreen ? 16.0 : 20.0, 
                ),
                child: _buildSubscribeButton(isSmallScreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPageDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: currentPage == index ? 20 : 6, 
      height: 6, 
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.white : Colors.grey[600],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
  Widget _buildBillingToggle(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 42 : 46, 
      padding: const EdgeInsets.all(3), 
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isAnnual = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isAnnual ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Monthly',
                    style: TextStyle(
                      color: !isAnnual ? Colors.black : Colors.grey[400],
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 13 : 15, 
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
                decoration: BoxDecoration(
                  color: isAnnual ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Annual',
                        style: TextStyle(
                          color: isAnnual ? Colors.black : Colors.grey[400],
                          fontWeight: FontWeight.w600,
                          fontSize:
                              isSmallScreen ? 13 : 15, 
                        ),
                      ),
                      if (isAnnual) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save 20%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  isSmallScreen ? 8 : 9, 
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
  Widget _buildPlanPage(bool isEssential, bool isTablet, bool isSmallScreen) {
    final monthlyPrice = isEssential ? 12 : 25;
    final annualPrice = isEssential ? 8 : 17;
    final currentPrice = isAnnual ? annualPrice : monthlyPrice;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 60.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              isSmallScreen ? 18.0 : 22.0,
            ), 
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEssential ? Icons.mic : Icons.auto_awesome,
                      color: isEssential ? Colors.grey[400] : Colors.amber,
                      size: isSmallScreen ? 18 : 22, 
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEssential ? 'Essential' : 'Premium',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (!isEssential) ...[
                  SizedBox(height: isSmallScreen ? 4 : 6), 
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isSmallScreen ? 8 : 9, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: isSmallScreen ? 16 : 20), 
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$$currentPrice',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 26 : 30, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '/month',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13, 
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                if (isAnnual) ...[
                  const SizedBox(height: 2), 
                  Text(
                    'Billed annually',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11, 
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 20 : 24), 
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              isSmallScreen ? 18.0 : 22.0,
            ), 
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s included:',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 14 : 16), 
                ..._getFeatures(isEssential).map(
                  (feature) => Padding(
                    padding: EdgeInsets.only(
                      bottom: isSmallScreen ? 8 : 10, 
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.green,
                          size: isSmallScreen ? 13 : 15, 
                        ),
                        const SizedBox(width: 6), 
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize:
                                  isSmallScreen ? 12 : 13, 
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
          SizedBox(height: isSmallScreen ? 20 : 30), 
        ],
      ),
    );
  }
  List<String> _getFeatures(bool isEssential) {
    return isEssential
        ? [
          'Send/Reply to Emails by Voice',
          'Voice Task Creation',
          'Voice Calendar Events',
          'Text Notifications',
          'Centralized Dashboard',
          'Secure Storage (2 GB)',
          'Up to 10 Priority Emails',
          'Basic voice recognition',
          'Standard customer support',
        ]
        : [
          'Voice Email Reading + Smart Search',
          'Smart Reminders',
          'Complete Voice Task Management',
          'Interactive Voice Notifications',
          'Advanced Voice Commands + Natural AI',
          'Extended Secure Storage (1 TB)',
          'Hybrid Concierge Service',
          'Up to 20 Priority Emails',
          'Advanced voice recognition with context',
          'Priority customer support',
          'Custom voice command training',
          'Integration with productivity tools',
        ];
  }
  Widget _buildSubscribeButton(bool isSmallScreen) {
    final planName = selectedPlan == 0 ? 'Essential' : 'Premium';
    final billingType = isAnnual ? 'Annual' : 'Monthly';
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 48 : 50, 
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child:
                _isLoading
                    ? SizedBox(
                      width: isSmallScreen ? 18 : 20,
                      height: isSmallScreen ? 18 : 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                    : Text(
                      'Start $planName ($billingType)',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8), 
        Text(
          '7-day free trial • Cancel anytime',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: isSmallScreen ? 12 : 13, 
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
