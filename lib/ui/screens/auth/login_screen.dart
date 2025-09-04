import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/ui/widgets/tab_switch.dart';
import 'package:frontend/ui/widgets/cosmic_background.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  Future<bool> handleLogin() async {
    final email = _formKey.currentState?.fields['email']?.value;
    final password = _formKey.currentState?.fields['password']?.value;
    if (email != null && password != null) {
      final success = await context.read<AuthProvider>().login(email, password);
      return success;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _handleFirstLaunch();
  }

  Future<void> _handleFirstLaunch() async {
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.setBool("firstOpen", false);

      print('SplashScreen: Updated firstOpen to false');
    } catch (e) {
      print('SplashScreen: Error updating firstOpen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Responsive breakpoints
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;

    // Theme-aware colors
    final isDark = theme.brightness == Brightness.dark;
    final headerTextColor = isDark ? Colors.white : Colors.white;
    final containerColor = isDark ? const Color(0xFF141D2E) : Colors.white;

    // Responsive sizing
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
            // Background
            const CosmicBackground(),

            // Header section
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

            // Title section
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

            // Main content container
            Positioned(
              top: screenHeight * containerTopPercent,
              left: 0,
              right: 0,
              bottom: 0,
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
                child: Column(
                  children: [
                    // Tab Switch
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      child: _buildTabSwitch(context),
                    ),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                        ),
                        child: Column(
                          children: [
                            // Form Section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 8,
                              ),
                              child: _buildForm(
                                context,
                                isSmallScreen,
                                isTablet,
                                isDark,
                              ),
                            ),

                            // Divider section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              child: _buildDivider(context, isDark),
                            ),

                            // Social Login Buttons
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 8,
                              ),
                              child: _buildSocialButtons(
                                context,
                                isSmallScreen,
                                isTablet,
                                isDark,
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 40 : 60),
                          ],
                        ),
                      ),
                    ),

                    // Terms text
                    _buildTermsSection(context, isSmallScreen, isDark),
                  ],
                ),
              ),
            ),
            if (authProvider.isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 134, 37, 224),
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
    final logoSize =
        isSmallScreen
            ? 20.0
            : isTablet
            ? 24.0
            : 22.0;
    final textSize =
        isSmallScreen
            ? 16.0
            : isTablet
            ? 20.0
            : 18.0;

    return Row(
      children: [
        SizedBox(
          width:
              isSmallScreen
                  ? 32
                  : isTablet
                  ? 40
                  : 36,
          height:
              isSmallScreen
                  ? 32
                  : isTablet
                  ? 40
                  : 36,
          child: Image.asset(
            'assets/images/logo1.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'ELYO AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: textSize,
            letterSpacing: 0.5,
          ),
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
          'Get Started now',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: titleSize,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create an account or log in to explore about our app',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.9),
            fontSize: subtitleSize,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitch(BuildContext context) {
    return AuthTabSwitch(
      selected: AuthTab.login,
      onChanged: (value) {
        if (value == AuthTab.signup) {
          context.pushNamed('signup');
        }
      },
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

    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          FormBuilderTextField(
            name: 'email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: fontSize,
              ),
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: fontSize,
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
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.email(),
            ]),
          ),

          const SizedBox(height: 16),

          // Password field
          FormBuilderTextField(
            name: 'password',
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: fontSize,
              ),
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: fontSize,
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
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(6),
            ]),
          ),

          const SizedBox(height: 16),

          // Remember me and Forgot password row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF3B77D8),
                      checkColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed('forgetPassword');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: const Color(0xFF3B77D8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Login button
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.saveAndValidate()) {
                  final email = _formKey.currentState?.fields['email']?.value;
                  final password =
                      _formKey.currentState?.fields['password']?.value;
                  final success = await context.read<AuthProvider>().login(
                    email,
                    password,
                  );
                  if (success && context.mounted) {
                    context.goNamed('home');
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.read<AuthProvider>().errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Color.fromARGB(255, 216, 59, 59),
                    ),
                  );
                }
              },
              child:
                  context.watch<AuthProvider>().isLoading
                      ? CircularProgressIndicator(
                        color: Color.fromARGB(255, 134, 37, 224),
                      )
                      : Text(
                        'Login',
                        style: TextStyle(
                          fontSize: fontSize + 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.onSurface.withValues(alpha: 0.2),
            thickness: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Or',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: colorScheme.onSurface.withValues(alpha: 0.2),
            thickness: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonHeight =
        isSmallScreen
            ? 48.0
            : isTablet
            ? 52.0
            : 50.0;
    final fontSize =
        isSmallScreen
            ? 14.0
            : isTablet
            ? 16.0
            : 15.0;
    final iconSize =
        isSmallScreen
            ? 18.0
            : isTablet
            ? 22.0
            : 20.0;

    final socialButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            style: socialButtonStyle,
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Using a fallback icon instead of asset image
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4),
                    borderRadius: BorderRadius.circular(iconSize / 2),
                  ),
                  child: const Icon(
                    Icons.g_mobiledata,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(fontSize: fontSize),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            style: socialButtonStyle,
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0078D4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.window,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Microsoft',
                  style: TextStyle(fontSize: fontSize),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection(
    BuildContext context,
    bool isSmallScreen,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = isSmallScreen ? 11.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: fontSize,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: 'By signing up, you agree to the '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terms of Service tapped'),
                      backgroundColor: Color(0xFF3B77D8),
                    ),
                  );
                },
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: const Color(0xFF3B77D8),
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF3B77D8),
                  ),
                ),
              ),
            ),
            const TextSpan(text: ' and '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data Processing Agreement tapped'),
                      backgroundColor: Color(0xFF3B77D8),
                    ),
                  );
                },
                child: Text(
                  'Data Processing Agreement',
                  style: TextStyle(
                    color: const Color(0xFF3B77D8),
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF3B77D8),
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
