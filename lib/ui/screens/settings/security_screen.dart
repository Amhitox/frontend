import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/utils/localization.dart';
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}
class _SecurityScreenState extends State<SecurityScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = true;
  bool _autoLock = true;
  String _autoLockTime = '5 minutes';
  @override
  void initState() {
    super.initState();
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
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    final theme = Theme.of(context);
    return Scaffold(
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
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(isTablet, isLargeScreen, theme),
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
                      children: [
                        _buildSecurityOverview(isTablet, isLargeScreen, theme),
                        SizedBox(height: isTablet ? 20 : 16),
                        _buildAuthenticationSection(
                          isTablet,
                          isLargeScreen,
                          theme,
                        ),
                        SizedBox(height: isTablet ? 20 : 16),
                        SizedBox(height: isTablet ? 20 : 16),
                        _buildPrivacySection(isTablet, isLargeScreen, theme),
                        SizedBox(height: isTablet ? 48 : 40),
                      ],
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
  Widget _buildHeader(bool isTablet, bool isLargeScreen, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(
        isLargeScreen
            ? 24
            : isTablet
            ? 20
            : 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pushNamed('settings'),
            child: Container(
              width: isTablet ? 44 : 40,
              height: isTablet ? 44 : 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
                size: isTablet ? 22 : 20,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.security,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize:
                    isLargeScreen
                        ? 24
                        : isTablet
                        ? 22
                        : 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 14 : 12,
              vertical: isTablet ? 8 : 6,
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
                  AppLocalizations.of(context)!.secure,
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
    );
  }
  Widget _buildSecurityOverview(
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: isTablet ? 70 : 60,
            height: isTablet ? 70 : 60,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: Colors.green,
              size: isTablet ? 35 : 30,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            AppLocalizations.of(context)!.accountSecure,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize:
                  isLargeScreen
                      ? 20
                      : isTablet
                      ? 18
                      : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            AppLocalizations.of(context)!.lastSecurityCheck,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: isTablet ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAuthenticationSection(
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
  ) {
    return _buildSection(
      AppLocalizations.of(context)!.authentication,
      Icons.lock_outline,
      [
        _buildSecurityItem(
          AppLocalizations.of(context)!.changePassword,
          AppLocalizations.of(context)!.updateAccountPassword,
          Icons.key,
          onTap: () => _changePassword(theme, isTablet),
          isTablet: isTablet,
          theme: theme,
        ),
      ],
      isTablet: isTablet,
      isLargeScreen: isLargeScreen,
      theme: theme,
    );
  }
  Widget _buildPrivacySection(
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
  ) {
    return _buildSection(
      AppLocalizations.of(context)!.privacyLock,
      Icons.privacy_tip_outlined,
      [
        _buildSecurityItem(
          AppLocalizations.of(context)!.loginHistory,
          AppLocalizations.of(context)!.viewLoginActivity,
          Icons.history,
          onTap: () => _showLoginHistory(),
          isTablet: isTablet,
          theme: theme,
        ),
      ],
      isTablet: isTablet,
      isLargeScreen: isLargeScreen,
      theme: theme,
    );
  }
  Widget _buildActivitySection(
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
  ) {
    return _buildSection(
      AppLocalizations.of(context)!.securityActivity,
      Icons.security,
      [
        _buildSecurityItem(
          AppLocalizations.of(context)!.activeSessions,
          AppLocalizations.of(context)!.manageActiveSessions,
          Icons.devices,
          onTap: () => _showActiveSessions(theme, isTablet),
          isTablet: isTablet,
          theme: theme,
        ),
        _buildSecurityItem(
          AppLocalizations.of(context)!.securityAlerts,
          AppLocalizations.of(context)!.configureSecurityNotifications,
          Icons.notification_important,
          onTap: () => _configureSecurityAlerts(theme, isTablet),
          isTablet: isTablet,
          theme: theme,
        ),
        _buildSecurityItem(
          AppLocalizations.of(context)!.dataExport,
          AppLocalizations.of(context)!.downloadAccountData,
          Icons.download,
          onTap: () => _exportData(theme, isTablet),
          isTablet: isTablet,
          theme: theme,
        ),
      ],
      isTablet: isTablet,
      isLargeScreen: isLargeScreen,
      theme: theme,
    );
  }
  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> items, {
    required bool isTablet,
    required bool isLargeScreen,
    required ThemeData theme,
  }) {
    return SizedBox(
      width: double.infinity,
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
  Widget _buildSecurityItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    required bool isTablet,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 16 : 12,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
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
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: isTablet ? 22 : 20,
            ),
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
    Function(bool) onChanged, {
    required bool isTablet,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
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
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
  void _changePassword(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            ),
            title: Text(
              AppLocalizations.of(context)!.changePassword,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  obscureText: true,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: isTablet ? 16 : 14,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.currentPassword,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),
                TextField(
                  obscureText: true,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: isTablet ? 16 : 14,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.newPassword,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.passwordUpdatedSuccess),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.update,
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
  void _changeAutoLockTime(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            ),
            title: Text(
              AppLocalizations.of(context)!.autoLockTimer,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['1 ${AppLocalizations.of(context)!.minute}', '5 ${AppLocalizations.of(context)!.minutes}', '15 ${AppLocalizations.of(context)!.minutes}', '30 ${AppLocalizations.of(context)!.minutes}', AppLocalizations.of(context)!.never]
                      .map(
                        (time) => RadioListTile<String>(
                          title: Text(
                            time,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                          value: time,
                          groupValue: _autoLockTime,
                          onChanged: (value) {
                            setState(() => _autoLockTime = value!);
                            Navigator.of(context).pop();
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }
  void _showLoginHistory() {
    context.push('/login-history');
  }
  void _showActiveSessions(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            ),
            title: Text(
              AppLocalizations.of(context)!.activeSessions,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSessionItem(
                  'iPhone 13 Pro',
                  AppLocalizations.of(context)!.currentDevice,
                  true,
                  theme,
                  isTablet,
                ),
                _buildSessionItem(
                  'MacBook Pro',
                  '${AppLocalizations.of(context)!.lastActive} 2 hours ago',
                  false,
                  theme,
                  isTablet,
                ),
                _buildSessionItem(
                  'iPad Air',
                  '${AppLocalizations.of(context)!.lastActive} 1 day ago',
                  false,
                  theme,
                  isTablet,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.close,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.allSessionsSignedOut),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.signOutOthers,
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
  Widget _buildSessionItem(
    String device,
    String status,
    bool isCurrent,
    ThemeData theme,
    bool isTablet,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 10 : 8),
      padding: EdgeInsets.all(isTablet ? 14 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
      ),
      child: Row(
        children: [
          Icon(
            isCurrent ? Icons.smartphone : Icons.laptop_mac,
            color:
                isCurrent
                    ? Colors.green
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            size: isTablet ? 22 : 20,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: isTablet ? 13 : 12,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 10 : 8,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              ),
              child: Text(
                AppLocalizations.of(context)!.current,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: isTablet ? 11 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
  void _configureSecurityAlerts(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            ),
            title: Text(
              AppLocalizations.of(context)!.securityAlerts,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.configureSecurityDescription,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.configure,
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
  void _exportData(ThemeData theme, bool isTablet) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            ),
            title: Text(
              AppLocalizations.of(context)!.dataExport,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.downloadDataDescription,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.dataExportStarted,
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.export,
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
}
