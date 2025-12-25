import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/utils/localization.dart';

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
  bool _isVerified = false;
  String _message = '';
  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _verifyEmail();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _message = AppLocalizations.of(context)!.invalidLink;
          });
        }
      });
    }
  }
  Future<void> _verifyEmail() async {
    try {
      await FirebaseAuth.instance.applyActionCode(widget.token!);
      setState(() {
        _isVerifying = false;
        _isVerified = true;
        _message = AppLocalizations.of(context)!.emailVerified;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.push('/login');
        }
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _isVerified = false;
        _message = AppLocalizations.of(context)!.verificationFailedMessage;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.emailVerification)),
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
                _message.isEmpty && _isVerifying ? AppLocalizations.of(context)!.verifyingEmail : _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!_isVerifying && !_isVerified) ...[
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: Text(AppLocalizations.of(context)!.goToLogin),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
