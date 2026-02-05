import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:frontend/utils/app_theme.dart';

class CmiPaymentScreen extends StatefulWidget {
  final String gatewayUrl;
  final Map<String, dynamic> params;

  const CmiPaymentScreen({
    super.key,
    required this.gatewayUrl,
    required this.params,
  });

  @override
  State<CmiPaymentScreen> createState() => _CmiPaymentScreenState();
}

class _CmiPaymentScreenState extends State<CmiPaymentScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onNavigationRequest: (NavigationRequest request) {
                final url = request.url.toLowerCase();
                if (url.contains("/payment/cmi/success") ||
                    url.contains("/payment/cmi/callback/ok")) {
                  _isSuccess = true;
                  return NavigationDecision.navigate;
                } else if (url.contains("/payment/cmi/fail") ||
                    url.contains("/payment/cmi/callback/fail")) {
                  _isSuccess = false;
                  return NavigationDecision.navigate;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(
            Uri.dataFromString(
              _generateHtmlForm(widget.gatewayUrl, widget.params),
              mimeType: 'text/html',
              encoding: Encoding.getByName('utf-8'),
            ),
          );
  }

  String _generateHtmlForm(String url, Map<String, dynamic> params) {
    String inputs = "";
    params.forEach((key, value) {
      inputs += '<input type="hidden" name="$key" value="$value" />';
    });
    return '''
      <html>
        <body onload="document.f.submit()">
          <form id="f" name="f" method="post" action="$url">
            $inputs
          </form>
        </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _isSuccess ?? false);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Secure Payment"),
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, _isSuccess ?? false),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
          ],
        ),
      ),
    );
  }
}
