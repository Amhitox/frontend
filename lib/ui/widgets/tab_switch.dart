import 'package:flutter/material.dart';
enum AuthTab { login, signup }
class AuthTabSwitch extends StatelessWidget {
  const AuthTabSwitch({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final AuthTab selected;
  final ValueChanged<AuthTab> onChanged;
  @override
  Widget build(BuildContext context) {
    final isLogin = selected == AuthTab.login;
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(AuthTab.login),
              child: _TabItem(text: 'Log In', selected: isLogin),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(AuthTab.signup),
              child: _TabItem(text: 'Sign Up', selected: !isLogin),
            ),
          ),
        ],
      ),
    );
  }
}
class _TabItem extends StatelessWidget {
  const _TabItem({required this.text, required this.selected});
  final String text;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow:
            selected
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? Colors.black : const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
