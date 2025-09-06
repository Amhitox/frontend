import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:frontend/ui/widgets/tab_switch.dart';
import 'package:frontend/ui/widgets/cosmic_background.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  String _selectedCountryCode = '+212';
  String _selectedCountryFlag = '🇲🇦';
  DateTime? _selectedDate;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  final List<Map<String, String>> _countries = [
    {'name': 'Morocco', 'code': '+212', 'flag': '🇲🇦'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'Spain', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'Italy', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
  ];

  @override
  Widget build(BuildContext context) {
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

                            // Terms section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              child: _buildTermsSection(
                                context,
                                isSmallScreen,
                                isDark,
                              ),
                            ),

                            // Divider section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 8,
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

                            SizedBox(height: isSmallScreen ? 30 : 40),
                          ],
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
          'Aixy',
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
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: titleSize,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Join us and start your productivity journey',
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
      selected: AuthTab.signup,
      onChanged: (value) {
        if (value == AuthTab.login) {
          context.go('/login');
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
          // Name fields
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  name: 'first_name',
                  labelText: 'First Name',
                  hintText: 'Enter first name',
                  isDark: isDark,
                  fontSize: fontSize,
                  validators: [FormBuilderValidators.required()],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  name: 'last_name',
                  labelText: 'Last Name',
                  hintText: 'Enter last name',
                  isDark: isDark,
                  fontSize: fontSize,
                  validators: [FormBuilderValidators.required()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email field
          _buildTextField(
            name: 'email',
            labelText: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            fontSize: fontSize,
            validators: [
              FormBuilderValidators.required(),
              FormBuilderValidators.email(),
            ],
          ),
          const SizedBox(height: 16),

          // Date of birth field
          _buildDateField(isDark, fontSize),
          const SizedBox(height: 16),

          // Phone number field
          _buildPhoneField(isDark, fontSize),
          const SizedBox(height: 16),

          // Password field
          _buildTextField(
            name: 'password',
            labelText: 'Password',
            hintText: 'Enter your password',
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility:
                () => setState(() => _obscurePassword = !_obscurePassword),
            isDark: isDark,
            fontSize: fontSize,
            validators: [
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(6),
            ],
          ),
          const SizedBox(height: 16),

          // Confirm password field
          _buildTextField(
            name: 'confirm_password',
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onToggleVisibility:
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
            isDark: isDark,
            fontSize: fontSize,
            validators: [
              FormBuilderValidators.required(),
              (value) {
                final password =
                    _formKey.currentState?.fields['password']?.value;
                if (value != password) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ],
          ),
          const SizedBox(height: 24),

          // Create Account button
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: _agreeToTerms ? _handleSignUp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _agreeToTerms
                        ? const Color(0xFF3B77D8)
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Account',
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

  Widget _buildTextField({
    required String name,
    required String labelText,
    required String hintText,
    required bool isDark,
    required double fontSize,
    required List<String? Function(String?)> validators,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
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
          borderSide: const BorderSide(color: Color(0xFF3B77D8), width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF141D2E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        suffixIcon:
            isPassword
                ? IconButton(
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                )
                : null,
      ),
      validator: FormBuilderValidators.compose(validators),
    );
  }

  Widget _buildDateField(bool isDark, double fontSize) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormBuilderDateTimePicker(
      name: 'date_of_birth',
      inputType: InputType.date,
      format: DateFormat('dd/MM/yyyy'),
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      onChanged: (value) {
        setState(() {
          _selectedDate = value;
        });
      },
      style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        hintText: 'Select your date of birth',
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
          borderSide: const BorderSide(color: Color(0xFF3B77D8), width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF141D2E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        suffixIcon: Icon(
          Icons.calendar_today,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          size: 20,
        ),
      ),
      validator: FormBuilderValidators.required(),
    );
  }

  Widget _buildPhoneField(bool isDark, double fontSize) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Country selector
        Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  isDark
                      ? const Color(0xFFD9D9D9).withValues(alpha: 0.3)
                      : const Color(0xFFD9D9D9),
            ),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF141D2E) : Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showCountryPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountryFlag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCountryCode,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Phone number input
        Expanded(
          child: FormBuilderTextField(
            name: 'phone',
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter phone number',
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
            // validator: FormBuilderValidators.required(),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            activeColor: const Color(0xFF3B77D8),
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: fontSize,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => context.go('/terms'),
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
                    onTap: () => context.go('/privacy'),
                    child: Text(
                      'Privacy Policy',
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
        ),
      ],
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
            onPressed: () => {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4),
                    borderRadius: BorderRadius.circular(10),
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
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.apple,
                    color: isDark ? Colors.black : Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Apple',
                  style: TextStyle(fontSize: fontSize),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Country',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      return ListTile(
                        leading: Text(
                          country['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          country['name']!,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        trailing: Text(
                          country['code']!,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCountryCode = country['code']!;
                            _selectedCountryFlag = country['flag']!;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _handleSignUp() async {
    if (_formKey.currentState != null &&
        _formKey.currentState!.saveAndValidate()) {
      final firstName = _formKey.currentState?.fields['first_name']?.value;
      final lastName = _formKey.currentState?.fields['last_name']?.value;
      final email = _formKey.currentState?.fields['email']?.value;
      final password = _formKey.currentState?.fields['password']?.value;
      final birthdayDate =
          _formKey.currentState?.fields['date_of_birth']?.value;
      final birthday =
          "${birthdayDate.year.toString().padLeft(4, '0')}-"
          "${birthdayDate.month.toString().padLeft(2, '0')}-"
          "${birthdayDate.day.toString().padLeft(2, '0')}";

      context.read<AuthProvider>().register(
        email,
        password,
        firstName,
        lastName,
        birthday,
      );
    }
  }
  //     // Show success message and navigate
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Account created successfully!'),
  //         backgroundColor: Color(0xFF3B77D8),
  //       ),
  //     );

  //     context.go('/home');
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please fill in all fields correctly'),
  //         backgroundColor: Color.fromARGB(255, 216, 59, 59),
  //       ),
  //     );
  //   }
  // }

  // void _socialSignUp(String provider) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Signing up with $provider...'),
  //       backgroundColor: const Color(0xFF3B77D8),
  //     ),
  //   );

  //   // Simulate social signup
  //   Future.delayed(const Duration(seconds: 1), () {
  //     if (mounted) {
  //       context.go('/home');
  //     }
  //   });
  // }
}
