import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/vpn_service.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/ui/widgets/glass_card.dart';

class VpnBlockerWrapper extends StatefulWidget {
  final Widget child;

  const VpnBlockerWrapper({super.key, required this.child});

  @override
  State<VpnBlockerWrapper> createState() => _VpnBlockerWrapperState();
}

class _VpnBlockerWrapperState extends State<VpnBlockerWrapper> with WidgetsBindingObserver {
  bool _isVpnActive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkVpn();
    // Check every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVpn());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVpn();
    }
  }

  Future<void> _checkVpn() async {
    final isActive = await VpnService().isVpnActive();
    if (isActive != _isVpnActive) {
      if (mounted) {
        setState(() {
          _isVpnActive = isActive;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVpnActive)
          Material(
            color: Colors.black.withOpacity(0.9),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.vpn_lock_rounded,
                        size: 64,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "VPN/Proxy Detected",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "For security reasons, this application cannot be used with a VPN or Proxy enabled. Please disable it to continue.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _checkVpn();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "I have disabled it",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white54,
                        ),
                        child: const Text("Exit App"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
