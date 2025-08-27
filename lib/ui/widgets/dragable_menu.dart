import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DraggableMenu extends StatefulWidget {
  const DraggableMenu({super.key});

  @override
  _DraggableMenuState createState() => _DraggableMenuState();
}

class _DraggableMenuState extends State<DraggableMenu>
    with TickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late AnimationController _iconRotationController;
  late Animation<double> _animation;

  final List<MenuItemData> _menuItems = [
    MenuItemData(Icons.home_rounded, 'Home', '/'),
    MenuItemData(Icons.email_rounded, 'Mail', '/mail'),
    MenuItemData(Icons.calendar_month_rounded, 'Calendar', '/calendar'),
    MenuItemData(Icons.task_alt_rounded, 'Tasks', '/task'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconRotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _iconRotationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
    _isMenuOpen
        ? (_animationController.forward(), _iconRotationController.forward())
        : (_animationController.reverse(), _iconRotationController.reverse());
  }

  void _navigateTo(String route) {
    context.push(route);
    _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    final buttonSize =
        isLargeScreen
            ? 80.0
            : isTablet
            ? 70.0
            : 60.0;
    final buttonBottom =
        isLargeScreen
            ? screenHeight * 0.12
            : isTablet
            ? screenHeight * 0.1
            : screenHeight * 0.08;
    final buttonRight =
        isLargeScreen
            ? screenWidth * 0.15
            : isTablet
            ? screenWidth * 0.12
            : screenWidth * 0.1;

    return Stack(
      children: [
        // Enhanced background overlay
        if (_isMenuOpen)
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(color: colors.scrim.withValues(alpha: 0.3)),
          ),

        // Menu button and items
        Positioned(
          right: buttonRight,
          bottom: buttonBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Menu items with simple animations
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Column(
                    children:
                        _menuItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final delay = index * 0.05;
                          final value = (_animation.value - delay).clamp(
                            0.0,
                            1.0,
                          );

                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 30),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      isLargeScreen
                                          ? 18
                                          : isTablet
                                          ? 16
                                          : 12,
                                ),
                                child: _buildMenuItem(
                                  item,
                                  isTablet,
                                  isLargeScreen,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),

              // Add margin between last item and main button
              SizedBox(
                height:
                    isLargeScreen
                        ? 24
                        : isTablet
                        ? 20
                        : 16,
              ),

              // Simple main button
              GestureDetector(
                onTap: _toggleMenu,
                child: AnimatedBuilder(
                  animation: _iconRotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _iconRotationController.value * 0.785,
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primary,
                              colors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: colors.onPrimary,
                          size:
                              isLargeScreen
                                  ? 36
                                  : isTablet
                                  ? 32
                                  : 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(MenuItemData item, bool isTablet, bool isLargeScreen) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enhanced label container
        Container(
          padding: EdgeInsets.symmetric(
            horizontal:
                isLargeScreen
                    ? 18
                    : isTablet
                    ? 16
                    : 14,
            vertical:
                isLargeScreen
                    ? 12
                    : isTablet
                    ? 10
                    : 8,
          ),
          margin: EdgeInsets.only(
            right:
                isLargeScreen
                    ? 12
                    : isTablet
                    ? 10
                    : 8,
          ),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? colors.surface.withValues(alpha: 0.95)
                    : colors.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(
              isLargeScreen
                  ? 12
                  : isTablet
                  ? 10
                  : 8,
            ),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? colors.shadow.withValues(alpha: 0.25)
                        : colors.shadow.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            item.label,
            style: TextStyle(
              color: colors.onSurface,
              fontSize:
                  isLargeScreen
                      ? 15
                      : isTablet
                      ? 14
                      : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        // Enhanced icon button
        GestureDetector(
          onTap: () => _navigateTo(item.route),
          child: Container(
            width:
                isLargeScreen
                    ? 56
                    : isTablet
                    ? 52
                    : 48,
            height:
                isLargeScreen
                    ? 56
                    : isTablet
                    ? 52
                    : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryContainer,
                  colors.primaryContainer.withValues(alpha: 0.8),
                ],
              ),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(
                    alpha: isDarkMode ? 0.25 : 0.15,
                  ),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: colors.onPrimaryContainer,
              size:
                  isLargeScreen
                      ? 26
                      : isTablet
                      ? 24
                      : 22,
            ),
          ),
        ),
      ],
    );
  }
}

class MenuItemData {
  final IconData icon;
  final String label;
  final String route;

  MenuItemData(this.icon, this.label, this.route);
}
