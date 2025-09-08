import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? token;

  const EmailVerificationScreen({super.key, this.token});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerifying = true;
  bool _isVerified = false;
  String _message = 'Verifying your email...';

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _verifyEmail();
    } else {
      setState(() {
        _isVerifying = false;
        _message = 'Invalid verification link';
      });
    }
  }

  Future<void> _verifyEmail() async {
    try {
      await FirebaseAuth.instance.applyActionCode(widget.token!);

      setState(() {
        _isVerifying = false;
        _isVerified = true;
        _message = 'Email verified successfully!';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/login');
        }
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _isVerified = false;
        _message =
            'Email verification failed: This can be caused by an invalid verification link or the email has already been verified.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Verification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isVerifying)
                const CircularProgressIndicator()
              else
                Icon(
                  _isVerified ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: _isVerified ? Colors.green : Colors.red,
                ),
              const SizedBox(height: 20),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!_isVerifying && !_isVerified) ...[
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Go to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
