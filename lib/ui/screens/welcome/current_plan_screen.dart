import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/utils/localization.dart';

class CurrentPlanScreen extends StatelessWidget {
  const CurrentPlanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F23)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.currentPlan,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final subscriptionTier =
                            authProvider.user?.subscriptionTier ?? 'FREE_TRIAL';
                        final isEssential = subscriptionTier == 'ESSENTIAL';
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient:
                                isEssential
                                    ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2D3748),
                                        Color(0xFF1A202C),
                                      ],
                                    )
                                    : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2),
                                      ],
                                    ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color:
                                  isEssential
                                      ? const Color(0xFF4A5568)
                                      : const Color(0xFFF093FB),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isEssential
                                        ? const Color(0xFF4A5568)
                                        : const Color(0xFFF093FB))
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient:
                                      isEssential
                                          ? const LinearGradient(
                                            colors: [
                                              Color(0xFF6B7280),
                                              Color(0xFF4B5563),
                                            ],
                                          )
                                          : const LinearGradient(
                                            colors: [
                                              Color(0xFFF093FB),
                                              Color(0xFFFF7043),
                                            ],
                                          ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  isEssential ? Icons.mic : Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                isEssential ? AppLocalizations.of(context)!.essentialPlan : AppLocalizations.of(context)!.premiumPlan,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                isEssential
                                    ? AppLocalizations.of(context)!.essentialPlanDesc
                                    : AppLocalizations.of(context)!.premiumPlanDesc,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[300],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              Column(
                                children: [
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => context.pop(),
                                    child: Text(
                                      AppLocalizations.of(context)!.backToHome,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
}
