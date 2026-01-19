import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/user_service.dart';
import 'package:frontend/ui/widgets/glass_card.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/utils/localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AccessGateScreen extends StatefulWidget {
  const AccessGateScreen({super.key});

  @override
  State<AccessGateScreen> createState() => _AccessGateScreenState();
}

class _AccessGateScreenState extends State<AccessGateScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isInactive = user?.status == 'inactive';

    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.goNamed('login');
      });
      return const Scaffold(backgroundColor: AppTheme.deepDark);
    }

    if (authProvider.canAccessApp && !isInactive) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.goNamed('home');
        });
      }
    }

    final loc = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppTheme.deepDark,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppTheme.primaryBlue)
                  : GlassCard(
                      borderRadius: 24,
                      opacity: 0.1,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Icon(
                              isInactive
                                  ? Icons.lock_outline_rounded
                                  : Icons.hourglass_empty_rounded,
                              size: 48,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isInactive
                                ? loc.accountInactive
                                : loc.freeTrialEnded,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 22 : 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isInactive
                                ? loc.inactiveAccountDesc
                                : loc.trialEndedDesc,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: isSmallScreen ? 14 : 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryBlue.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  context.pushNamed('subscription');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isInactive
                                      ? loc.activateSubscribe
                                      : loc.subscribeContinue,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          if (!isInactive) ...[
                            TextButton(
                              onPressed: _handleDeleteAccount,
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.errorRed,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                loc.deleteAccountLeave,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                          if (isInactive) ...[
                            TextButton(
                              onPressed: () => authProvider.logout(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white54,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(loc.logout),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBlue,
        title: Text(loc.deleteAccountTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(
          loc.deleteAccountDesc,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel,
                style: const TextStyle(color: AppTheme.primaryBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: Text(loc.deleteAndLogout),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userService = UserService(dio: authProvider.dio);

      if (authProvider.user?.id != null) {
        final currentUser = authProvider.user!;
        final inactiveUser = User(
          id: currentUser.id,
          email: currentUser.email,
          firstName: currentUser.firstName,
          lastName: currentUser.lastName,
          lang: currentUser.lang,
          status: 'inactive',
          workEmail: currentUser.workEmail,
          jobTitle: currentUser.jobTitle,
        );

        await userService.updateUser(authProvider.user!.id!, inactiveUser);
      }

      await authProvider.logout();
      if (mounted) context.goNamed('login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${loc.error}: $e'),
              backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
