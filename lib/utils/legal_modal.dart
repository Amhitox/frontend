import 'package:flutter/material.dart';
import 'package:frontend/utils/localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void showLegalModal(BuildContext context, String title, String rawContent) {
  showDialog(
    context: context,
    builder:
        (context) => LegalContentDialog(title: title, rawContent: rawContent),
  );
}

class LegalContentDialog extends StatelessWidget {
  final String title;
  final String rawContent;

  const LegalContentDialog({
    super.key,
    required this.title,
    required this.rawContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = rawContent;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E30) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Markdown(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.black87,
                  ),
                  h1: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  h2: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  h3: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  listBullet: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12, // match p
                  ),
                  blockquote: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[800],
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color:
                        isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                padding: const EdgeInsets.all(20),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
