import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/utils/localization.dart';
import 'package:frontend/providers/mail_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late final ThemeProvider themeProvider;
  late final LanguageProvider languageProvider;
  String _userName = 'Amhita Marouane';
  String _workEmail = 'amhita.maroua@gmail.com';
  String _selectedVoice = '';
  String _selectedLanguage = '';
  ThemeMode _selectedTheme = ThemeMode.system;
  final bool _pushNotifications = true;
  @override
  void initState() {
    super.initState();
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    // Values will be set in build method with localization
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _changeTheme(ThemeMode themeMode) {
    final l10n = AppLocalizations.of(context);

    themeProvider.setTheme(themeMode);
    setState(() {
      _selectedTheme = themeMode;
    });

    String themeName;
    switch (themeMode) {
      case ThemeMode.dark:
        themeName = l10n.dark;
        break;
      case ThemeMode.light:
        themeName = l10n.light;
        break;
      case ThemeMode.system:
        themeName = l10n.system;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.theme} ${l10n.changed} $themeName'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _changeLanguage(String languageCode) async {
    final l10n = AppLocalizations.of(context);
    await languageProvider.setLanguage(languageCode);

    var user = context.read<AuthProvider>().user;
    if (user != null) {
      user.lang = languageCode;
      await context.read<UserProvider>().updateUser(user.id, user);
      await context.read<AuthProvider>().updateUserInSession(user);
    }

    setState(() {
      _selectedLanguage = languageCode;
    });

    // Get display name for the new language
    // Note: l10n is still the old localization here, effectively
    String displayLanguage = languageCode == 'en' ? 'English' : 'Français';
    // Ideally we would use the new localization but this is fine for feedback

    if (!mounted) return;

    // Use a robust way to show snackbar, checking if context is still valid for ScaffoldMessenger
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.language} ${l10n.changed} $displayLanguage'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      // Ignore if ScaffoldMessenger cannot find a scaffold during rebuild
      print('Failed to show language change snackbar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    var user = context.watch<AuthProvider>().user ?? User();

    if (_selectedVoice.isEmpty) {
      _selectedVoice = user.voicePreferences?['defaultTtsVoiceId'] ?? 'nova';
      if (_selectedVoice != 'onyx' && _selectedVoice != 'nova') {
        _selectedVoice = 'nova';
      }
    }

    if (_selectedLanguage.isEmpty) {
      _selectedLanguage = AppLocalizations.of(context).locale.languageCode;
    }

    if (_selectedTheme != themeProvider.themeMode) {
      _selectedTheme = themeProvider.themeMode;
    }

    if (_workEmail == 'amhita.maroua@gmail.com' || _workEmail.isEmpty) {
      _workEmail = user.workEmail ?? user.email ?? '';
    }
    if (_userName == 'Amhita Marouane' || _userName.isEmpty) {
      _userName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
      if (_userName.isEmpty) _userName = 'User';
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        drawer: const SideMenu(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.scaffoldBackgroundColor,
                theme.colorScheme.surface.withValues(alpha: 0.1),
                theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildHeader(isTablet, isLargeScreen, theme, user),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                isLargeScreen
                                    ? 24
                                    : isTablet
                                    ? 20
                                    : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildEmailSection(
                                isTablet,
                                isLargeScreen,
                                theme,
                                user,
                              ),

                              // _buildConnectedAccountsSection(isTablet, isLargeScreen, theme),
                              _buildSection(
                                AppLocalizations.of(context).appPreferences,
                                Icons.tune_outlined,
                                [
                                  _buildVoiceSelector(isTablet, theme),
                                  _buildLanguageSelector(isTablet, theme, user),
                                  _buildThemeSelector(isTablet, theme),
                                ],
                                isTablet,
                                isLargeScreen,
                                theme,
                              ),
                              _buildSection(
                                AppLocalizations.of(context).supportFeedback,
                                Icons.help_outline,
                                [
                                  // _buildSettingItem(
                                  //   AppLocalizations.of(context).rateUs,
                                  //   AppLocalizations.of(context).loveTheApp,
                                  //   Icons.star_outline,
                                  //   showArrow: false,
                                  //   trailing: Row(
                                  //     mainAxisSize: MainAxisSize.min,
                                  //     children: List.generate(
                                  //       5,
                                  //       (index) => Icon(
                                  //         Icons.star,
                                  //         size: isTablet ? 18 : 16,
                                  //         color: Colors.orange.withValues(alpha: 0.7),
                                  //       ),
                                  //     ),
                                  //   ),
                                  //   onTap: () => _showRateDialog(theme, isTablet),
                                  //   isTablet: isTablet,
                                  //   theme: theme,
                                  // ),
                                  // _buildSettingItem(
                                  //   AppLocalizations.of(context).shareApp,
                                  //   AppLocalizations.of(context).tellYourFriends,
                                  //   Icons.share_outlined,
                                  //   onTap: () => _shareApp(theme, isTablet),
                                  //   isTablet: isTablet,
                                  //   theme: theme,
                                  // ),
                                  _buildSettingItem(
                                    AppLocalizations.of(context).helpSupport,
                                    AppLocalizations.of(context).getHelp,
                                    Icons.support_agent_outlined,
                                    onTap: () => context.push('/support'),
                                    isTablet: isTablet,
                                    theme: theme,
                                  ),
                                ],
                                isTablet,
                                isLargeScreen,
                                theme,
                              ),
                              _buildSection(
                                AppLocalizations.of(context).legalDocuments,
                                Icons.gavel_outlined,
                                [
                                  _buildSettingItem(
                                    // Changed from _buildSettingsTile to _buildSettingItem to match existing code
                                    AppLocalizations.of(context).termsOfService,
                                    AppLocalizations.of(
                                      context,
                                    ).termsAndConditions, // Added subtitle
                                    Icons.description_outlined,
                                    onTap: () => context.push('/terms'),
                                    isTablet: isTablet,
                                    theme: theme,
                                  ),
                                  _buildSettingItem(
                                    // Changed from _buildSettingsTile to _buildSettingItem to match existing code
                                    AppLocalizations.of(context).privacyPolicy,
                                    AppLocalizations.of(
                                      context,
                                    ).howWeProtectYourData, // Added subtitle
                                    Icons.privacy_tip_outlined,
                                    onTap: () => context.push('/privacy'),
                                    isTablet: isTablet,
                                    theme: theme,
                                  ),
                                  _buildSettingItem(
                                    // Changed from _buildSettingsTile to _buildSettingItem to match existing code
                                    AppLocalizations.of(
                                      context,
                                    ).generalConditions,
                                    AppLocalizations.of(
                                      context,
                                    ).termsAndConditions, // Assuming a similar subtitle for general conditions
                                    Icons.rule_outlined,
                                    onTap:
                                        () =>
                                            context.push('/generalConditions'),
                                    isTablet: isTablet,
                                    theme: theme,
                                  ),
                                  _buildSettingItem(
                                    AppLocalizations.of(context).appVersion,
                                    AppLocalizations.of(context).version123,
                                    Icons.system_update_outlined,
                                    showArrow: false,
                                    onTap:
                                        () => _checkForUpdates(theme, isTablet),
                                    isTablet: isTablet,
                                    theme: theme,
                                  ),
                                ],
                                isTablet,
                                isLargeScreen,
                                theme,
                              ),
                              SizedBox(height: isTablet ? 24 : 20),
                              _buildSignOutButton(isTablet, theme),
                              SizedBox(height: isTablet ? 48 : 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const DraggableMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
    User user,
  ) {
    _userName = '${user.firstName} ${user.lastName}';
    _workEmail = user.workEmail!;
    return Container(
      margin: EdgeInsets.all(
        isLargeScreen
            ? 24
            : isTablet
            ? 20
            : 16,
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.1),
            theme.colorScheme.surface.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                // onTap: () => _changeProfileImage(theme, isTablet),
                child: Container(
                  width: isTablet ? 72 : 64,
                  height: isTablet ? 72 : 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                        theme.colorScheme.secondary.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.onSurface,
                    size: isTablet ? 36 : 32,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize:
                                  isLargeScreen
                                      ? 22
                                      : isTablet
                                      ? 20
                                      : 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        GestureDetector(
                          onTap: () => _editName(theme, isTablet, user),
                          child: Container(
                            width: isTablet ? 28 : 24,
                            height: isTablet ? 28 : 24,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                isTablet ? 8 : 6,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              size: isTablet ? 16 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      _workEmail,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: isTablet ? 8 : 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12 : 10,
                        vertical: isTablet ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isTablet ? 8 : 6,
                            height: isTablet ? 8 : 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),

          _buildQuickActionButton(
            AppLocalizations.of(context).editProfile,
            Icons.person_outline,
            Colors.blue,
            () => context.push('/profile'),
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection(
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
    User user,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: isTablet ? 10 : 8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: isTablet ? 20 : 18,
                ),
                SizedBox(width: isTablet ? 10 : 8),
                Text(
                  AppLocalizations.of(context).emailManagement,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    fontSize:
                        isLargeScreen
                            ? 18
                            : isTablet
                            ? 16
                            : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.05,
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isTablet ? 44 : 40,
                        height: isTablet ? 44 : 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          size: isTablet ? 22 : 20,
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).registrationEmail,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: isTablet ? 16 : 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isTablet ? 4 : 2),
                            Text(
                              user.email ?? "test@gmail.com",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: isTablet ? 13 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 14 : 12,
                          vertical: isTablet ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 10 : 8,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).fixed,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: isTablet ? 12 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Row(
                    children: [
                      Container(
                        width: isTablet ? 44 : 40,
                        height: isTablet ? 44 : 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          color: Colors.blue,
                          size: isTablet ? 22 : 20,
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).workEmail,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: isTablet ? 16 : 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isTablet ? 4 : 2),
                            Text(
                              _workEmail,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: isTablet ? 13 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _editWorkEmail(theme, isTablet, user),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14 : 12,
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              isTablet ? 10 : 8,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).edit,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Row(
                    children: [
                      Container(
                        width: isTablet ? 44 : 40,
                        height: isTablet ? 44 : 40,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                        child: Icon(
                          Icons.star_outline_rounded,
                          color: Colors.orange,
                          size: isTablet ? 22 : 20,
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).priorityEmails,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: isTablet ? 16 : 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isTablet ? 4 : 2),
                            Text(
                              AppLocalizations.of(context).manageVipSenders,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: isTablet ? 13 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pushNamed('priorityEmails'),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14 : 12,
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              isTablet ? 10 : 8,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).manage,
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedAccountsSection(
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
  ) {
    final provider = context.watch<MailProvider>();
    final current = provider.currentProvider;

    return _buildSection(
      'Connected Accounts',
      Icons.cloud_queue,
      [
        _buildRunningAccountItem(
          'Gmail',
          Icons.mail_outline,
          current == 'gmail',
          () {
            if (current != 'gmail') {
              provider.setProvider('gmail');
            }
          },
          isTablet,
          theme,
        ),
        _buildRunningAccountItem(
          'Outlook',
          Icons.window_sharp,
          current == 'outlook',
          () {
            if (current != 'outlook') {
              provider.setProvider('outlook');
            }
          },
          isTablet,
          theme,
        ),
      ],
      isTablet,
      isLargeScreen,
      theme,
    );
  }

  Widget _buildRunningAccountItem(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    bool isTablet,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color:
              isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 16 : 12,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.onSurface,
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: isTablet ? 24 : 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 14 : 12,
          horizontal: isTablet ? 18 : 16,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isTablet ? 18 : 16),
            SizedBox(width: isTablet ? 10 : 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: isTablet ? 13 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> items,
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: isTablet ? 10 : 8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: isTablet ? 20 : 18,
                ),
                SizedBox(width: isTablet ? 10 : 8),
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    fontSize:
                        isLargeScreen
                            ? 18
                            : isTablet
                            ? 16
                            : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    Widget? trailing,
    bool showArrow = true,
    required bool isTablet,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 44 : 40,
              height: isTablet ? 44 : 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                size: isTablet ? 22 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: isTablet ? 4 : 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                (showArrow
                    ? Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      size: isTablet ? 22 : 20,
                    )
                    : const SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    bool isTablet,
    ThemeData theme,
  ) {
    return _buildSettingItem(
      title,
      subtitle,
      icon,
      showArrow: false,
      trailing: Switch(value: value, onChanged: onChanged),
      isTablet: isTablet,
      theme: theme,
    );
  }

  void _changeVoice(String voiceId) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _selectedVoice = voiceId;
    });

    try {
      await context.read<UserProvider>().updateVoicePreference(voiceId);

      var user = context.read<AuthProvider>().user;
      if (user != null) {
        user.voicePreferences = {'defaultTtsVoiceId': voiceId};
        await context.read<AuthProvider>().updateUserInSession(user);
      }

      if (!mounted) return;

      try {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.voice} ${l10n.changed}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        print('Failed to show voice change snackbar: $e');
      }
    } catch (e) {
      if (!mounted) return;
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update voice preference'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (_) {}
    }
  }

  Widget _buildVoiceSelector(bool isTablet, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    String displayVoice = _selectedVoice == 'onyx' ? l10n.male : l10n.female;

    return _buildSettingItem(
      l10n.voice,
      '${l10n.voice}: $displayVoice',
      Icons.record_voice_over_outlined,
      showArrow: false,
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedVoice,
            dropdownColor: theme.colorScheme.surface,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isTablet ? 13 : 12,
            ),
            items: [
              DropdownMenuItem(value: 'nova', child: Text(l10n.female)),
              DropdownMenuItem(value: 'onyx', child: Text(l10n.male)),
            ],
            onChanged: (value) {
              if (value != null) {
                _changeVoice(value);
              }
            },
          ),
        ),
      ),
      isTablet: isTablet,
      theme: theme,
    );
  }

  Widget _buildLanguageSelector(bool isTablet, ThemeData theme, User user) {
    final l10n = AppLocalizations.of(context);

    // Ensure _selectedLanguage is valid (it should be 'en' or 'fr')
    // If for some reason it's not, fallback to current locale
    String currentValue = _selectedLanguage;
    if (currentValue != 'en' && currentValue != 'fr') {
      currentValue = AppLocalizations.of(context).locale.languageCode;
    }

    return _buildSettingItem(
      l10n.language,
      '${l10n.language}: ${currentValue == 'en' ? l10n.english : l10n.french}',
      Icons.language_outlined,
      showArrow: false,
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            dropdownColor: theme.colorScheme.surface,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isTablet ? 13 : 12,
            ),
            items: [
              DropdownMenuItem(value: 'en', child: Text(l10n.english)),
              DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
            ],
            onChanged: (value) {
              if (value != null) {
                _changeLanguage(value);
              }
            },
          ),
        ),
      ),
      isTablet: isTablet,
      theme: theme,
    );
  }

  Widget _buildThemeSelector(bool isTablet, ThemeData theme) {
    final l10n = AppLocalizations.of(context);

    String getThemeName(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.dark:
          return l10n.dark;
        case ThemeMode.light:
          return l10n.light;
        case ThemeMode.system:
          return l10n.system;
      }
    }

    return _buildSettingItem(
      l10n.theme,
      '${l10n.theme}: ${getThemeName(_selectedTheme)}',
      Icons.palette_outlined,
      showArrow: false,
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ThemeMode>(
            value: _selectedTheme,
            dropdownColor: theme.colorScheme.surface,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isTablet ? 13 : 12,
            ),
            items:
                ThemeMode.values.map((ThemeMode mode) {
                  return DropdownMenuItem<ThemeMode>(
                    value: mode,
                    child: Text(getThemeName(mode)),
                  );
                }).toList(),
            onChanged: (ThemeMode? value) {
              if (value != null) {
                _changeTheme(value);
              }
            },
          ),
        ),
      ),
      isTablet: isTablet,
      theme: theme,
    );
  }

  Widget _buildSignOutButton(bool isTablet, ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        context.read<MailProvider>().clearCache();
        context.read<AuthProvider>().logout();
        context.go('/login');
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              color: Colors.red.withValues(alpha: 0.8),
              size: isTablet ? 22 : 20,
            ),
            SizedBox(width: isTablet ? 14 : 12),
            Text(
              AppLocalizations.of(context).signOut,
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.9),
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeProfileImage(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (context) => _buildCustomDialog(
            'Change Profile Photo',
            'Choose how you want to update your profile picture.',
            Icons.photo_camera,
            primaryAction: 'Choose Photo',
            onPrimaryAction: () {
              Navigator.of(context).pop();
            },
            theme: theme,
            isTablet: isTablet,
          ),
    );
  }

  void _editName(ThemeData theme, bool isTablet, User user) {
    final TextEditingController firstNameController = TextEditingController(
      text: user.firstName ?? '',
    );
    final TextEditingController lastNameController = TextEditingController(
      text: user.lastName ?? '',
    );

    // Validation function for names - only letters (including accented), at least 2 characters
    bool validateName(String name) {
      if (name.length < 2) return false;
      final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ]+$");
      return nameRegex.hasMatch(name);
    }

    // Show error dialog
    void showErrorDialog(BuildContext ctx, String message) {
      showDialog(
        context: ctx,
        builder:
            (errorContext) => AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: isTablet ? 28 : 24,
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Text(
                    AppLocalizations.of(ctx).error,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(errorContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: Text(
                    AppLocalizations.of(ctx).ok,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ),
              ],
            ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (dialogContext, setState) {
              bool isLoading = false;
              final l10n = AppLocalizations.of(context);
              return AlertDialog(
                backgroundColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                ),
                title: Text(
                  l10n.editName,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // First Name Field
                    TextField(
                      controller: firstNameController,
                      enabled: !isLoading,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: isTablet ? 16 : 14,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.firstName,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        hintText:
                            l10n.enter + ' ' + l10n.firstName.toLowerCase(),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    // Last Name Field
                    TextField(
                      controller: lastNameController,
                      enabled: !isLoading,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: isTablet ? 16 : 14,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.lastName,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        hintText:
                            l10n.enter + ' ' + l10n.lastName.toLowerCase(),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              final firstName = firstNameController.text.trim();
                              final lastName = lastNameController.text.trim();

                              // Validate both fields and show error dialog if invalid
                              if (!validateName(firstName)) {
                                showErrorDialog(
                                  dialogContext,
                                  l10n.invalidName,
                                );
                                return;
                              }

                              if (!validateName(lastName)) {
                                showErrorDialog(
                                  dialogContext,
                                  l10n.invalidName,
                                );
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              // Capture context/providers before async gap
                              final userProvider = context.read<UserProvider>();
                              final authProvider = context.read<AuthProvider>();
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );

                              try {
                                user.firstName = firstName;
                                user.lastName = lastName;

                                await userProvider.updateUser(user.id, user);
                                await authProvider.updateUserInSession(user);

                                // Check if the dialog is still mounted/active before popping
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              } catch (e) {
                                if (dialogContext.mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error updating name: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      disabledBackgroundColor: theme.colorScheme.primary
                          .withOpacity(0.5),
                    ),
                    child:
                        isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                            : Text(
                              l10n.save,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _editWorkEmail(ThemeData theme, bool isTablet, User user) {
    final TextEditingController emailController = TextEditingController(
      text: _workEmail,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (dialogContext, setState) {
              bool isLoading = false;
              return AlertDialog(
                backgroundColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                ),
                title: Text(
                  AppLocalizations.of(context).editWorkEmailTitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: isTablet ? 16 : 14,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).enterWorkEmail,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      AppLocalizations.of(context).cancel,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              final newEmail = emailController.text.trim();
                              if (newEmail.isNotEmpty &&
                                  newEmail != user.workEmail) {
                                setState(() {
                                  isLoading = true;
                                });

                                // Capture providers BEFORE async gap
                                final userProvider =
                                    context.read<UserProvider>();
                                final authProvider =
                                    context.read<AuthProvider>();
                                final mailProvider =
                                    context.read<MailProvider>();
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                final appLocalizations = AppLocalizations.of(
                                  context,
                                );

                                try {
                                  // Update the user object with new work email
                                  user.workEmail = newEmail;

                                  // Update in backend and local storage
                                  await userProvider.updateUser(user.id, user);
                                  await authProvider.updateUserInSession(user);

                                  // Update parent widget state if still mounted
                                  if (mounted) {
                                    this.setState(() {
                                      _workEmail = newEmail;
                                    });
                                  }

                                  // Disconnect mail session since work email changed
                                  await mailProvider.disconnect();

                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          appLocalizations
                                              .workEmailUpdatedReconnect,
                                        ),
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (dialogContext.mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error updating email: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      disabledBackgroundColor: theme.colorScheme.primary
                          .withOpacity(0.5),
                    ),
                    child:
                        isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                            : Text(
                              AppLocalizations.of(context).save,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showProfileMenu(ThemeData theme, bool isTablet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(top: isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 20),
                _buildMenuOption(
                  'View Profile',
                  Icons.person_outline,
                  () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                  theme,
                  isTablet,
                ),
                _buildMenuOption(
                  'Account Settings',
                  Icons.settings_outlined,
                  () {
                    Navigator.pop(context);
                    context.push('/security');
                  },
                  theme,
                  isTablet,
                ),
                SizedBox(height: isTablet ? 24 : 20),
              ],
            ),
          ),
    );
  }

  Widget _buildMenuOption(
    String title,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              size: isTablet ? 22 : 20,
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRateDialog(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            ),
            title: Row(
              children: [
                Container(
                  width: isTablet ? 36 : 32,
                  height: isTablet ? 36 : 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.orange,
                    size: isTablet ? 20 : 18,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  AppLocalizations.of(context).rateOurApp,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).rateOurAppFeedback,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _submitRating(index + 1);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 6 : 4,
                        ),
                        child: Icon(
                          Icons.star,
                          size: isTablet ? 36 : 32,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context).maybeLater,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _submitRating(int stars) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for rating us $stars stars!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareApp(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (context) => _buildCustomDialog(
            'Share App',
            'Share this amazing app with your friends and colleagues!',
            Icons.share,
            primaryAction: 'Share Now',
            primaryActionColor: Colors.blue,
            onPrimaryAction: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Share link copied to clipboard!'),
                  backgroundColor: Colors.blue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            theme: theme,
            isTablet: isTablet,
          ),
    );
  }

  void _checkForUpdates(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (context) => _buildCustomDialog(
            AppLocalizations.of(context).appUpdates,
            AppLocalizations.of(context).appUpdatesLatest,
            Icons.system_update,
            primaryAction: AppLocalizations.of(context).ok,
            primaryActionColor: Colors.green,
            theme: theme,
            isTablet: isTablet,
          ),
    );
  }

  void _showSignOutDialog(ThemeData theme, bool isTablet) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => _buildCustomDialog(
            l10n.signOut,
            l10n.signOutConfirmation,
            Icons.logout,
            primaryAction: l10n.signOut,
            primaryActionColor: Colors.red,
            onPrimaryAction: () {
              Navigator.of(context).pop();
              context.push('/login');
            },
            theme: theme,
            isTablet: isTablet,
          ),
    );
  }

  Widget _buildCustomDialog(
    String title,
    String content,
    IconData icon, {
    String? primaryAction,
    Color? primaryActionColor,
    VoidCallback? onPrimaryAction,
    required ThemeData theme,
    required bool isTablet,
  }) {
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
      ),
      title: Row(
        children: [
          Container(
            width: isTablet ? 36 : 32,
            height: isTablet ? 36 : 32,
            decoration: BoxDecoration(
              color: (primaryActionColor ?? Colors.blue).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
            ),
            child: Icon(
              icon,
              color: primaryActionColor ?? Colors.blue,
              size: isTablet ? 20 : 18,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontSize: isTablet ? 16 : 14,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context).cancel,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ),
        if (primaryAction != null)
          ElevatedButton(
            onPressed: onPrimaryAction ?? () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryActionColor ?? Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              ),
            ),
            child: Text(
              primaryAction,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
      ],
    );
  }
}
