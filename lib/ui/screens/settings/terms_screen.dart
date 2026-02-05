import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/utils/localization.dart';
import 'package:frontend/utils/legal_content.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:frontend/utils/legal_helper.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = LegalHelper.getLocalizedContent(
      context,
      LegalContent.terms,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context).termsOfService),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      ),
      body: Container(
        color:
            isDark
                ? const Color(0xFF16213E)
                : Colors.grey[50], // Background color
        child: Markdown(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
            h1: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            h2: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            h3: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            strong: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            listBullet: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            blockquote: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[800],
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          padding: const EdgeInsets.all(20.0),
        ),
      ),
    );
  }
}
