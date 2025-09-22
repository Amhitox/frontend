import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
class SideMenu extends StatefulWidget {
  const SideMenu({super.key});
  @override
  _SideMenuState createState() => _SideMenuState();
}
class _SideMenuState extends State<SideMenu> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final List<MenuItemData> _menuItems = [
    MenuItemData(Icons.home_outlined, 'Home', '/'),
    MenuItemData(Icons.mail_outline, 'Mail', '/mail'),
    MenuItemData(Icons.calendar_today_outlined, 'Calendar', '/calendar'),
    MenuItemData(Icons.task_alt_outlined, 'Tasks', '/task'),
    MenuItemData(Icons.analytics_outlined, 'Analytics', '/analytics'),
    MenuItemData(
      Icons.notifications_outlined,
      'Notifications',
      '/notifications',
    ),
    MenuItemData(Icons.settings_outlined, 'Settings', '/settings'),
  ];
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });
  }
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
  void _navigateTo(String route) {
    Navigator.of(context).pop(); 
    if (route != '/') {
      context.push(route);
    } else {
      context.push('/');
    }
  }
  bool _isRouteActive(String route) {
    final currentRoute = GoRouterState.of(context).uri.path;
    if (route == '/') {
      return currentRoute == '/' || currentRoute == '/home';
    }
    if (currentRoute == route) {
      return true;
    }
    if (currentRoute.startsWith('$route/')) {
      return true;
    }
    return false;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SlideTransition(
      position: _slideAnimation,
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  isDark
                      ? [
                        colorScheme.surface.withValues(alpha: 0.95),
                        colorScheme.surfaceContainer.withValues(alpha: 0.95),
                      ]
                      : [
                        colorScheme.surface.withValues(alpha: 0.98),
                        colorScheme.surfaceContainer.withValues(alpha: 0.95),
                      ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildMenuItems(context)),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final padding = isTablet ? 32.0 : 24.0;
    final avatarSize = isTablet ? 90.0 : 80.0;
    final nameSize = isTablet ? 20.0 : 18.0;
    final emailSize = isTablet ? 15.0 : 14.0;
    final iconSize = isTablet ? 45.0 : 40.0;
    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.primary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: isTablet ? 1.5 : 1,
              ),
            ),
            child: Icon(
              Icons.person,
              size: iconSize,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            '${user?.firstName ?? 'Test'} ${user?.lastName ?? 'Test'}',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: nameSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            user?.email ?? 'test@example.com',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: emailSize,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Container(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
  Widget _buildMenuItems(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(-50 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: _buildMenuItem(context, item, index),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildMenuItem(BuildContext context, MenuItemData item, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isActive = _isRouteActive(item.route);
    final verticalMargin = isTablet ? 6.0 : 4.0;
    final horizontalPadding = isTablet ? 20.0 : 16.0;
    final verticalPadding = isTablet ? 16.0 : 14.0;
    final iconSize = isTablet ? 26.0 : 24.0;
    final fontSize = isTablet ? 17.0 : 16.0;
    final borderRadius = isTablet ? 14.0 : 12.0;
    return Container(
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 4 : 0,
            height: isActive ? verticalPadding * 2 + iconSize : 0,
            decoration: BoxDecoration(
              color: isActive ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: isActive ? 8 : 0),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: () => _navigateTo(item.route),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? colorScheme.primaryContainer.withValues(
                              alpha: 0.6,
                            )
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color:
                          isActive
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                    ),
                    boxShadow:
                        isActive
                            ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: iconSize,
                        color:
                            isActive
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: isTablet ? 18 : 16),
                      Text(
                        item.label,
                        style: TextStyle(
                          color:
                              isActive
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                          fontSize: fontSize,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (item.label == 'Mail' || item.label == 'Notifications')
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 10 : 8,
                            vertical: isTablet ? 5 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(
                              isTablet ? 12 : 10,
                            ),
                          ),
                          child: Text(
                            item.label == 'Mail' ? '3' : '7',
                            style: TextStyle(
                              color: colorScheme.onError,
                              fontSize: isTablet ? 13 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final padding = isTablet ? 32.0 : 24.0;
    final versionIconSize = isTablet ? 18.0 : 16.0;
    final versionFontSize = isTablet ? 13.0 : 12.0;
    final logoutIconSize = isTablet ? 18.0 : 16.0;
    final logoutFontSize = isTablet ? 15.0 : 14.0;
    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Container(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.2),
            margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
          ),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: versionIconSize,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              SizedBox(width: isTablet ? 10 : 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: versionFontSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              onTap: () async {
                context.read<AuthProvider>().logout();
                context.pushNamed('login');
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout,
                      size: logoutIconSize,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: isTablet ? 10 : 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: logoutFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class MenuItemData {
  final IconData icon;
  final String label;
  final String route;
  MenuItemData(this.icon, this.label, this.route);
}
