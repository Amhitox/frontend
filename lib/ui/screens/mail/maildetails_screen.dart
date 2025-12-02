import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/email_message.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/mail_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MailDetailScreen extends StatefulWidget {
  final EmailMessage email;
  const MailDetailScreen({super.key, required this.email});
  @override
  State<MailDetailScreen> createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  // Email details state
  EmailMessage? _fullEmail;
  bool _isLoadingDetails = false;

  // WebView controller for email body
  late final WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _hasWebViewError = false;
  double _contentHeight = 0;

  // CRITICAL: The safety limit to prevent crashes on huge emails
  // 4000 logical pixels is roughly 4-5 screens long. Safe for textures.
  static const double _maxSafeHeight = 4000.0;
  @override
  void initState() {
    super.initState();

    // Initialize WebView
    _initWebView();

    // Fetch full email details
    _fetchEmailDetails();
  }

  void _initWebView() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(
            JavaScriptMode.unrestricted,
          ) // Required for height check
          ..setBackgroundColor(Colors.transparent)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                // Reset error state when starting new load
                if (mounted) {
                  setState(() {
                    _hasWebViewError = false;
                    _isWebViewLoading = true;
                    _contentHeight = 0; // Reset height
                  });
                }
              },
              onPageFinished: (String url) async {
                // 1. Calculate Content Height
                try {
                  final result = await _webViewController
                      .runJavaScriptReturningResult(
                        "document.documentElement.scrollHeight.toString()",
                      );

                  if (result is String) {
                    // Parse the height (remove quotes)
                    double? height = double.tryParse(
                      result.replaceAll('"', ''),
                    );

                    if (height != null && mounted) {
                      setState(() {
                        _contentHeight = height;
                        _isWebViewLoading = false;
                      });
                      print(
                        '✅ WebView page loaded successfully - Height: ${height.toStringAsFixed(0)}px',
                      );

                      // Enable text selection via JavaScript
                      try {
                        _webViewController.runJavaScript(
                          "document.body.style.webkitUserSelect = 'text'; document.body.style.userSelect = 'text';",
                        );
                      } catch (e) {
                        print("Text selection enable error: $e");
                      }
                    } else if (mounted) {
                      setState(() => _isWebViewLoading = false);
                    }
                  } else if (mounted) {
                    setState(() => _isWebViewLoading = false);
                  }
                } catch (e) {
                  print("Height calculation error: $e");
                  if (mounted) {
                    setState(() => _isWebViewLoading = false);
                  }
                }
              },
              onNavigationRequest: (NavigationRequest request) async {
                // Handle link clicks - open external links in browser
                final uri = Uri.tryParse(request.url);
                if (uri != null &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  // Open link in external browser
                  try {
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (launched) {
                      // Successfully opened in browser, prevent WebView navigation
                      return NavigationDecision.prevent;
                    }
                  } catch (e) {
                    print('Error launching URL: $e');
                  }
                }
                // Prevent navigating away from email content
                return NavigationDecision.prevent;
              },
              onWebResourceError: (WebResourceError error) {
                // ERR_CLEARTEXT_NOT_PERMITTED (-2) is common in emails with HTTP images
                // This is non-critical and doesn't prevent email display
                final isCleartextError =
                    error.errorCode == -2 ||
                    error.description.contains('CLEARTEXT') ||
                    error.description.contains('cleartext');

                // Only log and handle critical errors
                if (!isCleartextError) {
                  print(
                    '⚠️ WebView error (${error.errorCode}): ${error.description}',
                  );

                  // Only set error state for critical errors that prevent content display
                  // Network errors (-2, -6, -8) are often non-critical for email content
                  final isCriticalError =
                      error.errorCode != -6 && // ERR_FILE_NOT_FOUND
                      error.errorCode != -8; // ERR_CONNECTION_TIMED_OUT

                  if (isCriticalError && mounted) {
                    setState(() {
                      _hasWebViewError = true;
                      _isWebViewLoading = false;
                    });
                  }
                }
                // Silently ignore cleartext errors - they're expected in email HTML
              },
            ),
          );

    // Initial load - defer until after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadContentToWebView();
      }
    });
  }

  void _loadContentToWebView() {
    if (!mounted) return;

    // Debounce rapid calls to reduce lag
    Future.delayed(const Duration(milliseconds: 10), () {
      if (!mounted) return;

      String content = _fullEmail?.body ?? widget.email.body;
      if (content.isEmpty) {
        content = widget.email.snippet;
      }

      // Security: Remove scripts
      content = content.replaceAll(
        RegExp(
          r'<script[^>]*>.*?</script>',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      );

      // Get theme for background color (safe to access after mounted check)
      final theme = Theme.of(context);

      // Get theme colors
      final bgColor = theme.colorScheme.surface.value
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2);
      final textColor = theme.colorScheme.onSurface.value
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2);

      // Wrap HTML with proper mobile viewport and styling
      final htmlContent = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta charset="UTF-8">
    <style>
      body { 
        margin: 0; 
        padding: 16px; 
        /* Bottom padding for action sheet */
        padding-bottom: 120px; 
        font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        background-color: #$bgColor;
        color: #$textColor;
        overflow-x: hidden;
        word-wrap: break-word;
        -webkit-text-size-adjust: 100%;
        /* Enable text selection */
        user-select: text;
        -webkit-user-select: text;
        -webkit-touch-callout: default;
        /* Performance optimizations for smoother scrolling */
        -webkit-overflow-scrolling: touch;
        -webkit-transform: translateZ(0);
        transform: translateZ(0);
        will-change: scroll-position;
      }
      img { 
        max-width: 100% !important; 
        height: auto !important; 
        display: block;
        -webkit-transform: translateZ(0);
        transform: translateZ(0);
      }
      table {
        max-width: 100% !important;
        width: 100% !important;
        border-collapse: collapse;
        table-layout: auto;
      }
      td, th {
        word-wrap: break-word;
        overflow-wrap: break-word;
      }
      iframe {
        max-width: 100% !important;
      }
      video {
        max-width: 100% !important;
        height: auto !important;
      }
      * {
        box-sizing: border-box;
      }
      /* Hide scrollbars inside webview so it looks like part of the page */
      ::-webkit-scrollbar { display: none; }
      /* Performance optimization: Enable hardware acceleration for scrolling */
      html {
        -webkit-overflow-scrolling: touch;
        overflow-scrolling: touch;
      }
    </style>
  </head>
  <body>$content</body>
</html>
''';

      // Reset loading state when loading new content
      if (mounted) {
        setState(() {
          _isWebViewLoading = true;
          _hasWebViewError = false;
        });
      }

      // Load HTML content - baseUrl: null allows HTTP images
      _webViewController.loadHtmlString(htmlContent, baseUrl: null);
      print('📧 Loaded HTML content to WebView (${content.length} chars)');
    });
  }

  Future<void> _fetchEmailDetails() async {
    if (_isLoadingDetails) return;

    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final auth = context.read<AuthProvider>();
      final mailService = MailService(dio: auth.dio);

      // Try to fetch full email details from API
      final response = await mailService.getEmailDetails(widget.email.id);

      if (response != null) {
        // Parse the full email details from API
        final fullEmail = _parseFullEmailMessage(response);
        setState(() {
          _fullEmail = fullEmail;
        });
        // Reload WebView with new content
        _loadContentToWebView();
      } else {
        // If API endpoint doesn't exist or returns null, use the email data we already have
        // The list endpoint already includes body data, so we can use widget.email
        // Keep HTML as-is for proper rendering
        print(
          '⚠️ Email details endpoint not available, using existing email data',
        );

        // Keep HTML as-is - we'll render it properly in the UI
        // Only remove script tags for security
        String body = widget.email.body;
        if (body.isNotEmpty) {
          // Check if it's HTML and sanitize if needed
          final isHtmlBody = _isHtmlContent(body);
          if (isHtmlBody) {
            // Remove script tags for security (but keep HTML structure)
            body = body.replaceAll(
              RegExp(
                r'<script[^>]*>.*?</script>',
                caseSensitive: false,
                dotAll: true,
              ),
              '',
            );
            // Keep style tags and CSS for proper email rendering
            // Only script tags are removed for security
            // Also remove potentially dangerous event handlers
            body = body.replaceAll(
              RegExp(
                r'\s*on\w+\s*=\s*["\x27].*?["\x27]',
                caseSensitive: false,
                dotAll: true,
              ),
              '',
            );
          }
        }

        // Create a new EmailMessage with HTML body (preserved for rendering)
        final cleanedEmail = EmailMessage(
          id: widget.email.id,
          threadId: widget.email.threadId,
          draftId: widget.email.draftId,
          sender: widget.email.sender,
          senderEmail: widget.email.senderEmail,
          subject: widget.email.subject,
          snippet: widget.email.snippet,
          body: body.isNotEmpty ? body : widget.email.snippet,
          date: widget.email.date,
          isUnread: widget.email.isUnread,
          labelIds: widget.email.labelIds,
          hasAttachments: widget.email.hasAttachments,
          attachments: widget.email.attachments,
          headers: widget.email.headers,
        );

        setState(() {
          _fullEmail = cleanedEmail;
        });
        // Reload WebView with new content
        _loadContentToWebView();
      }

      // Mark email as read when viewed
      if (widget.email.isUnread) {
        await mailService.markAsRead(widget.email.id);
      }
    } catch (e) {
      print('❌ Error fetching email details: $e');
      // Fallback to using existing email data
      setState(() {
        _fullEmail = widget.email;
      });
      // Reload WebView with fallback content
      _loadContentToWebView();
    } finally {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _deleteEmail() async {
    try {
      final auth = context.read<AuthProvider>();
      final mailService = MailService(dio: auth.dio);

      final success = await mailService.deleteEmail(widget.email.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to mail list
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleReadStatus() async {
    try {
      final auth = context.read<AuthProvider>();
      final mailService = MailService(dio: auth.dio);

      final success =
          widget.email.isUnread
              ? await mailService.markAsRead(widget.email.id)
              : await mailService.markAsUnread(widget.email.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.email.isUnread ? 'Marked as read' : 'Marked as unread',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling read status: $e');
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Email'),
            content: Text(
              'Are you sure you want to delete this email? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteEmail();
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  EmailMessage _parseFullEmailMessage(Map<String, dynamic> data) {
    // Extract headers
    final headers = data['headers'] as Map<String, dynamic>? ?? {};

    // Extract sender information from headers
    String sender = 'Unknown Sender';
    String senderEmail = '';

    final fromHeader = headers['from'] as String? ?? '';
    if (fromHeader.isNotEmpty) {
      // Parse "Name <email@domain.com>" format
      if (fromHeader.contains('<') && fromHeader.contains('>')) {
        final parts = fromHeader.split('<');
        sender = parts[0].trim();
        senderEmail = parts[1].replaceAll('>', '').trim();
      } else {
        // Just email address
        senderEmail = fromHeader;
        sender = fromHeader.split('@').first;
      }
    }

    // Extract subject from headers
    final subject = headers['subject'] as String? ?? '(No Subject)';

    // Extract other fields
    final snippet = data['snippet'] as String? ?? '';

    // Try multiple possible locations for body content
    String body = '';
    bool isHtml = false;

    // Check direct body field first (most common case based on API response)
    if (data['body'] != null) {
      final bodyData = data['body'];
      if (bodyData is String && bodyData.isNotEmpty) {
        body = bodyData;
        // Check if it's HTML using improved detection
        isHtml = _isHtmlContent(body);
      }
    } else if (data['textBody'] != null &&
        data['textBody'].toString().isNotEmpty) {
      body = data['textBody'].toString();
      // Check if textBody is actually HTML
      isHtml = _isHtmlContent(body);
    } else if (data['htmlBody'] != null &&
        data['htmlBody'].toString().isNotEmpty) {
      body = data['htmlBody'].toString();
      isHtml = true; // Explicitly marked as HTML
    } else if (data['payload'] != null) {
      // Gmail API sometimes nests body in payload
      final payload = data['payload'] as Map<String, dynamic>?;
      if (payload != null) {
        if (payload['body'] != null) {
          final payloadBody = payload['body'] as Map<String, dynamic>?;
          if (payloadBody != null && payloadBody['data'] != null) {
            // Base64url decoded body (Gmail API uses base64url)
            try {
              final encoded = payloadBody['data'] as String;
              // Convert base64url to base64
              final base64 = encoded.replaceAll('-', '+').replaceAll('_', '/');
              // Add padding if needed
              final padding = (4 - base64.length % 4) % 4;
              final paddedBase64 = base64 + ('=' * padding);
              body = utf8.decode(base64Decode(paddedBase64));
            } catch (e) {
              print('⚠️ Error decoding base64 body: $e');
            }
          }
        }
        // Check parts for multipart messages
        if (body.isEmpty && payload['parts'] != null) {
          final parts = payload['parts'] as List<dynamic>?;
          if (parts != null) {
            for (var part in parts) {
              if (part is Map<String, dynamic>) {
                final mimeType = part['mimeType'] as String? ?? '';
                final partBody = part['body'] as Map<String, dynamic>?;
                if (partBody != null &&
                    partBody['data'] != null &&
                    (mimeType == 'text/plain' || mimeType == 'text/html')) {
                  try {
                    final encoded = partBody['data'] as String;
                    // Convert base64url to base64
                    final base64 = encoded
                        .replaceAll('-', '+')
                        .replaceAll('_', '/');
                    // Add padding if needed
                    final padding = (4 - base64.length % 4) % 4;
                    final paddedBase64 = base64 + ('=' * padding);
                    final decodedBody = utf8.decode(base64Decode(paddedBase64));
                    // Prefer HTML parts over plain text
                    if (mimeType == 'text/html' ||
                        (body.isEmpty && decodedBody.isNotEmpty)) {
                      body = decodedBody;
                      isHtml =
                          mimeType == 'text/html' ||
                          _isHtmlContent(decodedBody);
                      if (mimeType == 'text/html') break; // Prefer HTML
                    } else if (body.isEmpty) {
                      body = decodedBody;
                      isHtml = _isHtmlContent(decodedBody);
                    }
                  } catch (e) {
                    print('⚠️ Error decoding part body: $e');
                  }
                }
              }
            }
          }
        }
      }
    }

    // Fallback to snippet if body is still empty
    if (body.isEmpty) {
      body = snippet;
    }

    // Final check: if body is not empty, verify if it's HTML
    if (body.isNotEmpty && !isHtml) {
      isHtml = _isHtmlContent(body);
    }

    // Keep HTML as-is - we'll render it properly in the UI
    // Remove script tags and dangerous attributes for security
    // Keep style tags and CSS for proper email rendering
    if (isHtml && body.isNotEmpty) {
      // Remove script tags for security (but keep the HTML structure)
      body = body.replaceAll(
        RegExp(
          r'<script[^>]*>.*?</script>',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      );
      // Keep style tags and CSS for proper email rendering
      // Only script tags are removed for security
      // Also remove potentially dangerous event handlers
      body = body.replaceAll(
        RegExp(
          r'\s*on\w+\s*=\s*["\x27].*?["\x27]',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      );
      print('✅ Preserved HTML content for rendering (${body.length} chars)');
    }

    print('📧 Parsed email body length: ${body.length}, isHtml: $isHtml');

    // Parse date
    DateTime date = DateTime.now();
    final dateString = data['date'] as String? ?? headers['date'] as String?;
    if (dateString != null) {
      try {
        date = DateTime.parse(dateString);
      } catch (e) {
        print('❌ Error parsing date: $dateString');
      }
    }

    // Check if unread
    final labelIds = data['labelIds'] as List<dynamic>? ?? [];
    final isUnread = labelIds.contains('UNREAD');

    // Check for attachments
    final hasAttachments = data['hasAttachments'] == true;

    // Create EmailHeaders object
    final emailHeaders = EmailHeaders(
      subject: headers['subject'] as String?,
      from: headers['from'] as String?,
      to: headers['to'] as String?,
      date: headers['date'] as String?,
    );

    return EmailMessage(
      id: data['id'] as String? ?? '',
      threadId: data['threadId'] as String? ?? data['id'] as String? ?? '',
      draftId: data['draftId'] as String?,
      sender: sender,
      senderEmail: senderEmail,
      subject: subject,
      snippet: snippet,
      body: body,
      date: date,
      isUnread: isUnread,
      labelIds: labelIds.map((e) => e.toString()).toList(),
      hasAttachments: hasAttachments,
      attachments: null,
      headers: emailHeaders,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (_isLoadingDetails && _fullEmail == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Logic: Is the email HUGE?
    bool isContentHuge = _contentHeight > _maxSafeHeight;

    // Logic: Calculate render height
    // If Huge: cap it to screen height (internal scroll).
    // If Normal: expand to full content height (native scroll).
    double renderHeight =
        _contentHeight > 0
            ? (isContentHuge
                ? MediaQuery.of(context).size.height
                : _contentHeight)
            : 400; // default loading height

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Switched to CustomScrollView for unified scrolling with conditional gesture handling
      body: CustomScrollView(
        slivers: [
          // AppBar with header info
          SliverAppBar(
            leading: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.goNamed('mail');
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: isTablet ? 24 : 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                _buildEnhancedAvatar(isTablet, theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.email.sender,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                      Text(
                        widget.email.formattedTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (widget.email.labelIds.contains('IMPORTANT'))
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.priority_high,
                        color: Colors.red,
                        size: isTablet ? 18 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Important',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            floating: true, // Appears immediately on scroll up
            snap: true, // Snaps into view
            pinned: false, // Scrolls away completely
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),

          // The Metadata Section (Subject and Date)
          SliverToBoxAdapter(child: _buildMetadataSection(theme, isTablet)),

          // Attachments Section (if any)
          if (widget.email.hasAttachments && widget.email.attachments != null)
            SliverToBoxAdapter(
              child: _buildAttachmentsSection(theme, isTablet),
            ),

          // The Email Body with conditional gesture handling
          SliverToBoxAdapter(
            child: SizedBox(
              height: renderHeight,
              child: _buildEmailBody(theme, isTablet, isContentHuge),
            ),
          ),

          // Add extra space at the bottom for safety
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomSheet: _buildActionBottomSheet(theme, isTablet),
    );
  }

  Widget _buildEnhancedHeader(ThemeData theme, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.lightImpact();
                context.goNamed('mail');
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: isTablet ? 24 : 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildEnhancedAvatar(isTablet, theme),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.email.sender,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.email.formattedTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.email.labelIds.contains('IMPORTANT'))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.priority_high,
                    color: Colors.red,
                    size: isTablet ? 18 : 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Important',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEnhancedAvatar(bool isTablet, ThemeData theme) {
    final initials = widget.email.senderInitials;
    return Hero(
      tag: 'avatar_${widget.email.sender}',
      child: Container(
        width: isTablet ? 56 : 48,
        height: isTablet ? 56 : 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataSection(ThemeData theme, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.email.subject,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email.formattedTime,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(ThemeData theme, bool isTablet) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 20 : 16,
        isTablet ? 24 : 20,
        isTablet ? 16 : 12,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 4 : 2,
        vertical: isTablet ? 8 : 4,
      ),
      child:
          _isLoadingDetails
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
              : _buildEmailBody(
                theme,
                isTablet,
                false,
              ), // Default to false for unused method
    );
  }

  Widget _buildEmailBody(ThemeData theme, bool isTablet, bool isContentHuge) {
    String displayContent = '';

    // Get the content to display
    if (_fullEmail?.body.isNotEmpty == true) {
      displayContent = _fullEmail!.body;
    } else if (widget.email.body.isNotEmpty) {
      displayContent = widget.email.body;
    } else if (widget.email.snippet.isNotEmpty) {
      displayContent = widget.email.snippet;
    } else {
      displayContent = 'No content available';
    }

    // Check if content is HTML
    final isHtml = _isHtmlContent(displayContent);

    print('📧 Email body - Length: ${displayContent.length}, isHtml: $isHtml');
    if (displayContent.length > 0 && displayContent.length < 200) {
      print(
        '📧 Content preview: ${displayContent.substring(0, displayContent.length > 100 ? 100 : displayContent.length)}...',
      );
    }

    if (isHtml) {
      // Render HTML using WebView in a Gmail-like container
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child:
            _isWebViewLoading
                ? Container(
                  height: 400, // Minimum height to prevent layout thrashing
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading email...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : _hasWebViewError
                ? Container(
                  height: 200,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load email content',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _hasWebViewError = false;
                              _isWebViewLoading = true;
                            });
                            _loadContentToWebView();
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
                : RepaintBoundary(
                  // Isolate repaints for better performance
                  child: WebViewWidget(
                    controller: _webViewController,
                    // Gesture Logic:
                    // If content is HUGE: Allow WebView to handle drag (internal scroll)
                    // If content is NORMAL: Disallow WebView drag (pass to CustomScrollView)
                    gestureRecognizers:
                        isContentHuge
                            ? {
                              Factory<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer(),
                              ),
                            }
                            : {}, // Empty set lets clicks pass but scrolling go to parent
                  ),
                ),
      );
    } else {
      // Plain text content in Gmail-like container
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 16 : 12,
        ),
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: SelectableText(
          displayContent,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: isTablet ? 16 : 15,
            height: 1.7,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
            letterSpacing: 0.2,
          ),
        ),
      );
    }
  }

  bool _isHtmlContent(String content) {
    if (content.isEmpty) return false;
    final trimmed = content.trim();
    final lowerTrimmed = trimmed.toLowerCase();

    // Check for explicit HTML declarations
    if (lowerTrimmed.startsWith('<!doctype html') ||
        lowerTrimmed.startsWith('<html')) {
      return true;
    }

    // Check for HTML tags (more comprehensive)
    final htmlTagPattern = RegExp(
      r'<(html|body|div|p|span|h[1-6]|table|tr|td|th|ul|ol|li|a|img|br|hr|strong|em|b|i|u|blockquote|pre|code|style|link|meta|title|head)',
      caseSensitive: false,
    );

    if (htmlTagPattern.hasMatch(trimmed)) {
      return true;
    }

    // Check for HTML entities (common in HTML emails)
    if (RegExp(r'&(nbsp|amp|lt|gt|quot|#\d+);').hasMatch(trimmed)) {
      // Only treat as HTML if it also contains HTML-like structure
      if (trimmed.contains('<') && trimmed.contains('>')) {
        return true;
      }
    }

    // Check for inline styles or CSS
    if (RegExp(
      r'style\s*=\s*["\x27]',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return true;
    }

    return false;
  }

  Widget _buildAttachmentsSection(ThemeData theme, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: isTablet ? 20 : 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Attachments',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.email.attachments!.map(
            (attachment) => _buildAttachmentItem(theme, isTablet, attachment),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(
    ThemeData theme,
    bool isTablet,
    EmailAttachment attachment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            attachment.fileIcon,
            style: TextStyle(fontSize: isTablet ? 24 : 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.filename,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  attachment.formattedSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading ${attachment.filename}...'),
                ),
              );
            },
            icon: Icon(
              Icons.download_rounded,
              color: theme.colorScheme.primary,
              size: isTablet ? 20 : 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBottomSheet(ThemeData theme, bool isTablet) {
    return Container(
      height: isTablet ? 80 : 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon:
                    widget.email.isUnread
                        ? Icons.mark_email_read_rounded
                        : Icons.mark_email_unread_rounded,
                label: widget.email.isUnread ? 'Mark Read' : 'Mark Unread',
                onTap: _toggleReadStatus,
                theme: theme,
                isTablet: isTablet,
              ),
              _buildActionButton(
                icon: Icons.reply_all_rounded,
                label: 'Reply All',
                onTap: () {},
                theme: theme,
                isTablet: isTablet,
              ),
              _buildActionButton(
                icon: Icons.forward_rounded,
                label: 'Forward',
                onTap: () {},
                theme: theme,
                isTablet: isTablet,
              ),
              _buildActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                onTap: () => _showDeleteConfirmation(),
                theme: theme,
                isTablet: isTablet,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isTablet,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 12 : 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: isTablet ? 24 : 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: isTablet ? 12 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isUnread() {
    return widget.email.isUnread;
  }
}
