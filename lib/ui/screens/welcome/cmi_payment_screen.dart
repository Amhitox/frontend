import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check for Success/Fail Redirects
            if (request.url.contains("payment/success") || request.url.contains("okUrl")) { 
               // Handle Success
               if (mounted) Navigator.pop(context, true);
               return NavigationDecision.prevent;
            } else if (request.url.contains("payment/fail") || request.url.contains("failUrl")) { 
               // Handle Failure
               if (mounted) Navigator.pop(context, false);
               return NavigationDecision.prevent;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Payment"),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
