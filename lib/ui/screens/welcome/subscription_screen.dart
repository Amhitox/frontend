import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/sub_provider.dart';
import 'package:frontend/ui/widgets/glass_card.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/utils/localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'cmi_payment_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isLoading = false;

  Future<void> _handleCmiPayment(double amount, String planName) async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final subProvider = context.read<SubProvider>();
      final user = authProvider.user;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first')),
        );
        return;
      }

      final userInfo = {
        'email': user.email ?? 'user@example.com',
        'firstName': user.firstName ?? 'User',
        'lastName': user.lastName ?? 'Name',
        'phone': '', // Add phone if available
      };

      final paymentData = await subProvider.initiateCmiPayment(
        amount: amount,
        userInfo: userInfo,
      );

      if (paymentData != null && mounted) {
        final gatewayUrl = paymentData['url'];
        final params = Map<String, dynamic>.from(paymentData['params'] ?? {});

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CmiPaymentScreen(
              gatewayUrl: gatewayUrl,
              params: params,
            ),
          ),
        );

        if (result == true && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Payment Successful! Welcome to $planName'), backgroundColor: Colors.green),
           );
           // Refresh user profile to get new subscription status if backend handled webhook
           await authProvider.refreshUserProfile();
           context.goNamed('home');
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Payment Failed or Cancelled'), backgroundColor: Colors.red),
           );
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to initiate payment'), backgroundColor: Colors.red),
           );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.deepDark, AppTheme.darkBlue],
          ),
        ),
        child: SafeArea(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  loc.chooseYourPlan,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                _buildPlanCard(
                  title: loc.premiumIntl,
                  price: "49.00 USD",
                  amount: 49.00,
                  features: [
                     "Unlimited AI Emails",
                     "Calendar Integration",
                     "Priority Support"
                  ],
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                _buildPlanCard(
                  title: loc.proBusinessIntl,
                  price: "99.00 USD",
                  amount: 99.00,
                  features: [
                     "All Premium Features",
                     "Team Collaboration",
                     "Advanced Analytics"
                  ],
                  color: Colors.purpleAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required double amount,
    required List<String> features,
    required Color color,
  }) {
    return GlassCard(
      borderRadius: 20,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              price,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ...features.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(e, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleCmiPayment(amount, title),
                child: const Text(
                  "Subscribe Now",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
