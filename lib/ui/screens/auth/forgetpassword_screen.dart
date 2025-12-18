import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/cosmic_background.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  int _secondsLeft = 0;
  Timer? _timer;
  bool _isLoading = false;
  bool _emailSent = false;
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }
  @override
  void dispose() {
    _emailController.dispose();
    _slideController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;
    final isDark = theme.brightness == Brightness.dark;
    final headerTextColor = isDark ? Colors.white : Colors.white;
    final containerColor = isDark ? const Color(0xFF141D2E) : Colors.white;
    final headerTopPercent =
        isLandscape
            ? 0.03
            : isSmallScreen
            ? 0.04
            : 0.05;
    final titleTopPercent =
        isLandscape
            ? 0.08
            : isSmallScreen
            ? 0.10
            : 0.12;
    final containerTopPercent =
        isLandscape
            ? 0.18
            : isSmallScreen
            ? 0.22
            : 0.25;
    final horizontalPadding = isTablet ? 48.0 : 32.0;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            const CosmicBackground(),
            Positioned(
              top: screenHeight * headerTopPercent,
              left: screenWidth * 0.05,
              child: GestureDetector(
                onTap: () => context.pushNamed('login'),
                child: Container(
                  width:
                      isSmallScreen
                          ? 36
                          : isTablet
                          ? 44
                          : 40,
                  height:
                      isSmallScreen
                          ? 36
                          : isTablet
                          ? 44
                          : 40,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size:
                        isSmallScreen
                            ? 18
                            : isTablet
                            ? 22
                            : 20,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * headerTopPercent,
              left: screenWidth * 0.07,
              right: screenWidth * 0.07,
              child: _buildHeader(
                context,
                isSmallScreen,
                isTablet,
                headerTextColor,
              ),
            ),
            Positioned(
              top: screenHeight * titleTopPercent,
              left: screenWidth * 0.07,
              right: screenWidth * 0.07,
              child: _buildTitle(
                context,
                isSmallScreen,
                isTablet,
                headerTextColor,
              ),
            ),
            Positioned(
              top: screenHeight * containerTopPercent,
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      if (isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height:
                              isSmallScreen
                                  ? 30
                                  : isTablet
                                  ? 50
                                  : 40,
                        ),
                        _buildIconSection(isSmallScreen, isTablet),
                        SizedBox(
                          height:
                              isSmallScreen
                                  ? 20
                                  : isTablet
                                  ? 28
                                  : 24,
                        ),
                        if (!_emailSent) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _buildForm(
                              context,
                              isSmallScreen,
                              isTablet,
                              isDark,
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _buildSuccessSection(
                              context,
                              isSmallScreen,
                              isTablet,
                              isDark,
                            ),
                          ),
                        ],
                        SizedBox(
                          height:
                              isSmallScreen
                                  ? 30
                                  : isTablet
                                  ? 50
                                  : 40,
                        ),
                        if (!_emailSent)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _buildHelpSection(
                              context,
                              isSmallScreen,
                              isTablet,
                              isDark,
                            ),
                          ),
                        SizedBox(
                          height:
                              isSmallScreen
                                  ? 40
                                  : isTablet
                                  ? 70
                                  : 60,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
    Color textColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width:
              isSmallScreen
                  ? 50
                  : isTablet
                  ? 58
                  : 54,
        ),
      ],
    );
  }
  Widget _buildTitle(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
    Color textColor,
  ) {
    final titleSize =
        isSmallScreen
            ? 24.0
            : isTablet
            ? 32.0
            : 28.0;
    final subtitleSize =
        isSmallScreen
            ? 14.0
            : isTablet
            ? 16.0
            : 15.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _emailSent ? 'Check your email' : 'Forgot Password?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: titleSize,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _emailSent
              ? 'We\'ve sent a recovery link to your email'
              : 'Don\'t worry, we\'ll help you reset it',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.9),
            fontSize: subtitleSize,
            height: 1.3,
          ),
        ),
      ],
    );
  }
  Widget _buildIconSection(bool isSmallScreen, bool isTablet) {
    final iconSize =
        isSmallScreen
            ? 70.0
            : isTablet
            ? 90.0
            : 80.0;
    final iconInnerSize =
        isSmallScreen
            ? 35.0
            : isTablet
            ? 45.0
            : 40.0;
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color:
            _emailSent
                ? const Color(0xFF3B77D8).withValues(alpha: 0.1)
                : const Color(0xFF3B77D8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B77D8).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        _emailSent ? Icons.mark_email_read : Icons.lock_reset,
        size: iconInnerSize,
        color: const Color(0xFF3B77D8),
      ),
    );
  }
  Widget _buildForm(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buttonHeight =
        isSmallScreen
            ? 48.0
            : isTablet
            ? 56.0
            : 52.0;
    final fontSize =
        isSmallScreen
            ? 14.0
            : isTablet
            ? 16.0
            : 15.0;
    final titleSize =
        isSmallScreen
            ? 16.0
            : isTablet
            ? 20.0
            : 18.0;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your email address',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll send you a link to reset your password',
            style: TextStyle(
              fontSize: fontSize,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: fontSize,
              ),
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: fontSize,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark
                          ? const Color(0xFFD9D9D9).withValues(alpha: 0.3)
                          : const Color(0xFFD9D9D9),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark
                          ? const Color(0xFFD9D9D9).withValues(alpha: 0.3)
                          : const Color(0xFFD9D9D9),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3B77D8),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF141D2E) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B77D8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: fontSize + 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: buttonHeight - 4,
            child: TextButton(
              onPressed: () => context.push('/login'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSuccessSection(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buttonHeight =
        isSmallScreen
            ? 48.0
            : isTablet
            ? 56.0
            : 52.0;
    final fontSize =
        isSmallScreen
            ? 14.0
            : isTablet
            ? 16.0
            : 15.0;
    final titleSize =
        isSmallScreen
            ? 18.0
            : isTablet
            ? 22.0
            : 20.0;
    return Column(
      children: [
        Text(
          'Email sent successfully!',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to:',
          style: TextStyle(
            fontSize: fontSize,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C1421) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF141D2E) : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _emailController.text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3B77D8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B77D8).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF3B77D8),
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your email and click the reset link to create a new password. The link will expire in 1 hour.',
                style: TextStyle(
                  fontSize: fontSize - 1,
                  color: const Color(0xFF3B77D8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _secondsLeft > 0 ? null : _handleResendEmail,
          child: Text(
            _secondsLeft > 0
                ? "Resend in $_secondsLeft s"
                : "Didn't receive the email? Resend",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3B77D8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B77D8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Back to Login',
              style: TextStyle(
                fontSize: fontSize + 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildHelpSection(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize =
        isSmallScreen
            ? 11.0
            : isTablet
            ? 14.0
            : 12.0;
    final titleSize =
        isSmallScreen
            ? 13.0
            : isTablet
            ? 15.0
            : 14.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1421) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF141D2E) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Need help?',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Make sure you enter the email address you used to create your account\n'
            '• Check your spam or junk folder if you don\'t see the email\n'
            '• The reset link will expire after 1 hour for security',
            style: TextStyle(
              fontSize: fontSize,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.push('/support'),
            child: Row(
              children: [
                Icon(
                  Icons.support_agent,
                  color: const Color(0xFF3B77D8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: const Color(0xFF3B77D8),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _handleResetPassword() async {
    if (_secondsLeft > 0) return;
    final authProvider = context.read<AuthProvider>();
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      await authProvider.forgotPassword(_emailController.text);
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset link sent successfully!'),
            backgroundColor: const Color(0xFF3B77D8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    setState(() {
      _secondsLeft = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 1) {
        timer.cancel();
      }
      setState(() {
        _secondsLeft--;
      });
    });
  }
  void _handleResendEmail() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.forgotPassword(_emailController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reset link sent again. Please check your email.'),
        backgroundColor: const Color(0xFF3B77D8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
