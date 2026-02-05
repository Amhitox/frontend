import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:frontend/ui/widgets/tab_switch.dart';
import 'package:frontend/ui/widgets/cosmic_background.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/utils/localization.dart';
import 'package:frontend/utils/legal_content.dart';
import 'package:frontend/utils/legal_modal.dart';
import 'package:frontend/utils/legal_helper.dart';

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
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'Spain', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'Italy', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
  ];

  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordFocused = false;

  // Password validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _checkPassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 9;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(
        RegExp(r'[!@#\$&*~^%_+=(){}\[\]:;<>?\/|,-]'),
      );
    });
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
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      child: _buildTabSwitch(context),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                        ),
                        child: Column(
                          children: [
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
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              child: _buildCndpSection(
                                context,
                                isSmallScreen,
                                isTablet,
                                isDark,
                              ),
                            ),
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
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 8,
                              ),
                              child: _buildDivider(context, isDark),
                            ),
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
                            SizedBox(height: isSmallScreen ? 60 : 80),
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
          AppLocalizations.of(context).appTitle,
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
          AppLocalizations.of(context).createAccount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: titleSize,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context).joinUs,
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
          context.push('/login');
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
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  name: 'first_name',
                  labelText: AppLocalizations.of(context).firstName,
                  hintText: AppLocalizations.of(context).enterFirstName,
                  isDark: isDark,
                  fontSize: fontSize,
                  validators: [
                    FormBuilderValidators.required(
                      errorText: AppLocalizations.of(context).firstNameRequired,
                    ),
                    (value) {
                      if (value == null || value.isEmpty) return null;
                      // Only allow letters (including accented), spaces, hyphens, and apostrophes
                      final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$");
                      if (!nameRegex.hasMatch(value)) {
                        return AppLocalizations.of(context).invalidName;
                      }
                      // Must have at least 2 letter characters
                      final letterCount =
                          value.replaceAll(RegExp(r"[^a-zA-ZÀ-ÿ]"), '').length;
                      if (letterCount < 2) {
                        return AppLocalizations.of(context).invalidName;
                      }
                      return null;
                    },
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  name: 'last_name',
                  labelText: AppLocalizations.of(context).lastName,
                  hintText: AppLocalizations.of(context).enterLastName,
                  isDark: isDark,
                  fontSize: fontSize,
                  validators: [
                    FormBuilderValidators.required(
                      errorText: AppLocalizations.of(context).lastNameRequired,
                    ),
                    (value) {
                      if (value == null || value.isEmpty) return null;
                      // Only allow letters (including accented), spaces, hyphens, and apostrophes
                      final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$");
                      if (!nameRegex.hasMatch(value)) {
                        return AppLocalizations.of(context).invalidName;
                      }
                      // Must have at least 2 letter characters
                      final letterCount =
                          value.replaceAll(RegExp(r"[^a-zA-ZÀ-ÿ]"), '').length;
                      if (letterCount < 2) {
                        return AppLocalizations.of(context).invalidName;
                      }
                      return null;
                    },
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            name: 'email',
            labelText: AppLocalizations.of(context).email,
            hintText: AppLocalizations.of(context).enterEmail,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            fontSize: fontSize,
            validators: [
              FormBuilderValidators.required(
                errorText: AppLocalizations.of(context).emailRequired,
              ),
              FormBuilderValidators.email(
                errorText: AppLocalizations.of(context).invalidEmail,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateField(isDark, fontSize),
          const SizedBox(height: 16),
          _buildPhoneField(isDark, fontSize),
          const SizedBox(height: 16),
          _buildTextField(
            name: 'password',
            labelText: AppLocalizations.of(context).password,
            hintText: AppLocalizations.of(context).enterPassword,
            isPassword: true,
            obscureText: _obscurePassword,
            focusNode: _passwordFocusNode,
            onChanged: (value) => _checkPassword(value ?? ''),
            onToggleVisibility:
                () => setState(() => _obscurePassword = !_obscurePassword),
            isDark: isDark,
            fontSize: fontSize,
            validators: [
              FormBuilderValidators.required(
                errorText: AppLocalizations.of(context).passwordRequired,
              ),
              (value) {
                if (value == null || value.isEmpty) return null;
                List<String> missing = [];
                if (value.length < 9) missing.add("9+ chars");
                if (!value.contains(RegExp(r'[A-Z]'))) missing.add("uppercase");
                if (!value.contains(RegExp(r'[a-z]'))) missing.add("lowercase");
                if (!value.contains(RegExp(r'[0-9]'))) missing.add("number");
                if (!value.contains(
                  RegExp(r'[!@#\$&*~^%_+=(){}\[\]:;<>?\/|,-]'),
                )) {
                  missing.add("special char");
                }
                if (missing.isNotEmpty) {
                  return "Missing: ${missing.join(', ')}";
                }
                return null;
              },
            ],
          ),
          if (_isPasswordFocused) ...[
            const SizedBox(height: 8),
            _buildPasswordRequirements(isDark, fontSize),
          ],
          const SizedBox(height: 16),
          _buildTextField(
            name: 'confirm_password',
            labelText: AppLocalizations.of(context).confirmPassword,
            hintText: AppLocalizations.of(context).confirmPasswordHint,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onToggleVisibility:
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
            isDark: isDark,
            fontSize: fontSize,
            validators: [
              FormBuilderValidators.required(
                errorText: AppLocalizations.of(context).passwordRequired,
              ),
              (value) {
                final password =
                    _formKey.currentState?.fields['password']?.value;
                if (value != password) {
                  return AppLocalizations.of(context).passwordMatchError;
                }
                return null;
              },
            ],
          ),
          const SizedBox(height: 24),
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
              child:
                  context.watch<AuthProvider>().isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        AppLocalizations.of(context).createAccount,
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
    FocusNode? focusNode,
    void Function(String?)? onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return FormBuilderTextField(
      name: name,
      focusNode: focusNode,
      onChanged: onChanged,
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
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      onChanged: (value) {
        setState(() {
          _selectedDate = value;
        });
      },
      style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).dateOfBirth,
        hintText: AppLocalizations.of(context).selectDate,
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
        Expanded(
          child: FormBuilderTextField(
            name: 'phone',
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colorScheme.onSurface, fontSize: fontSize),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).phone,
              hintText: AppLocalizations.of(context).enterPhone,
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
            validator: FormBuilderValidators.required(),
          ),
        ),
      ],
    );
  }

  Widget _buildCndpSection(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = isSmallScreen ? 11.0 : 12.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: fontSize,
                height: 1.4,
              ),
              children: [
                TextSpan(text: AppLocalizations.of(context).agreeToCndp),
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
                TextSpan(text: AppLocalizations.of(context).agreeToTerms),
                WidgetSpan(
                  child: GestureDetector(
                    onTap:
                        () => showLegalModal(
                          context,
                          AppLocalizations.of(context).termsOfService,
                          LegalHelper.getLocalizedContent(
                            context,
                            LegalContent.terms,
                          ),
                        ),
                    child: Text(
                      AppLocalizations.of(context).termsOfService,
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
                TextSpan(text: ' ${AppLocalizations.of(context).and} '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap:
                        () => showLegalModal(
                          context,
                          AppLocalizations.of(context).privacyPolicy,
                          LegalHelper.getLocalizedContent(
                            context,
                            LegalContent.privacy,
                          ),
                        ),
                    child: Text(
                      AppLocalizations.of(context).privacyPolicy,
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
          AppLocalizations.of(context).or,
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

  Widget _buildPasswordRequirements(bool isDark, double fontSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141D2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).passwordRequirements,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: fontSize - 1,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            context,
            "9+ Characters",
            _hasMinLength,
            fontSize,
          ),
          _buildRequirementItem(
            context,
            "Uppercase Letter",
            _hasUppercase,
            fontSize,
          ),
          _buildRequirementItem(
            context,
            "Lowercase Letter",
            _hasLowercase,
            fontSize,
          ),
          _buildRequirementItem(context, "Number", _hasNumber, fontSize),
          _buildRequirementItem(
            context,
            "Special Character",
            _hasSpecialChar,
            fontSize,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    BuildContext context,
    String text,
    bool isMet,
    double fontSize,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color:
                isMet
                    ? Colors.green
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Text(
            text, // Using hardcoded text for now as specific keys might be missing, normally use AppLocalizations
            style: TextStyle(
              fontSize: fontSize - 2,
              color:
                  isMet
                      ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.9)
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
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
        if (!Platform.isAndroid)
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
      final formattedDate = DateFormat("yyyy-MM-dd").format(birthdayDate);
      final rawPhone = _formKey.currentState?.fields['phone']?.value ?? '';
      String cleanedPhone = rawPhone.trim();
      if (cleanedPhone.startsWith('0')) {
        cleanedPhone = cleanedPhone.substring(1);
      }
      final fullPhone = '$_selectedCountryCode$cleanedPhone';
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.register(
        email,
        password,
        firstName,
        lastName,
        phone: fullPhone,
        birthday: formattedDate,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? AppLocalizations.of(context).success,
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.push('/login');
          }
        });
      } else if (mounted && success == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ??
                  AppLocalizations.of(context).errorOccurred,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
