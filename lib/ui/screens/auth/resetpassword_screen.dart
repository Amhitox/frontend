import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/utils/localization.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/cosmic_background.dart';
import 'package:provider/provider.dart';
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.token});
  final String? token;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}
class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _slideController.dispose();
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
          AppLocalizations.of(context)!.resetPasswordTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: titleSize,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.createSecurePassword,
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
        color: const Color(0xFF3B77D8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B77D8).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.lock_reset,
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
            AppLocalizations.of(context)!.createNewPassword,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.passwordRequirements,
            style: TextStyle(
              fontSize: fontSize,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
            decoration: InputDecoration(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.newPassword,
              hintText: AppLocalizations.of(context)!.newPasswordHint,
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: fontSize,
              ),
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: fontSize,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
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
                return AppLocalizations.of(context)!.passwordRequired;
              }
              if (value.length < 8) {
                return AppLocalizations.of(context)!.passwordLengthError;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
            decoration: InputDecoration(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.confirmPassword,
              hintText: AppLocalizations.of(context)!.confirmNewPasswordHint,
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: fontSize,
              ),
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: fontSize,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
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
                return AppLocalizations.of(context)!.passwordRequired;
              }
              if (value != _passwordController.text) {
                return AppLocalizations.of(context)!.passwordMatchError;
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
                        AppLocalizations.of(context)!.resetPasswordTitle,
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
                    AppLocalizations.of(context)!.backToLogin,
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
  void _handleResetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      if (widget.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.passwordResetFailed),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final response = await context.read<AuthProvider>().resetPassword(
        widget.token ?? "",
        _passwordController.text,
      );
      setState(() => _isLoading = false);
      if (response && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.passwordResetSuccess),
            backgroundColor: const Color(0xFF28A745),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.pushNamed('login');
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.passwordResetFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
