import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/utils/localization.dart';
import 'package:frontend/utils/legal_content.dart';

class GeneralConditionsScreen extends StatefulWidget {
  const GeneralConditionsScreen({super.key});

  @override
  State<GeneralConditionsScreen> createState() => _GeneralConditionsScreenState();
}

class _GeneralConditionsScreenState extends State<GeneralConditionsScreen> {
  String _rawContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rawContent = LegalContent.generalConditions;
    _isLoading = false;
  }

  // Future<void> _loadContent() async { ... } removed

  String _parseContent(String rawContent, BuildContext context) {
    if (rawContent.startsWith('Error')) return rawContent;
    
    final locale = Localizations.localeOf(context);
    final isFrench = locale.languageCode == 'fr';
    final buffer = StringBuffer();

    // Split by separator line (3 or more dashes)
    final sections = rawContent.split(RegExp(r'-{3,}'));

    for (var section in sections) {
      if (section.trim().isEmpty) continue;

      // Find FR and EN markers
      final frMatch = RegExp(r'(?:^|\n)\s*FR\s*:', caseSensitive: false).firstMatch(section);
      final enMatch = RegExp(r'(?:^|\n)\s*EN\s*:', caseSensitive: false).firstMatch(section);

      if (frMatch != null && enMatch != null) {
        // We have both markers
        
        // Header is everything before the first marker
        final firstMarkerStart = (frMatch.start < enMatch.start) ? frMatch.start : enMatch.start;
        final header = section.substring(0, firstMarkerStart).trim();
        if (header.isNotEmpty) buffer.writeln('$header\n');

        if (isFrench) {
          // Content for FR
          if (frMatch.start < enMatch.start) {
            final content = section.substring(frMatch.end, enMatch.start).trim();
            buffer.writeln('$content\n');
          } else {
            final content = section.substring(frMatch.end).trim();
            buffer.writeln('$content\n');
          }
        } else {
          // Content for EN
          if (enMatch.start < frMatch.start) {
             final content = section.substring(enMatch.end, frMatch.start).trim();
             buffer.writeln('$content\n');
          } else {
             final content = section.substring(enMatch.end).trim();
             buffer.writeln('$content\n');
          }
        }
      } else {
        buffer.writeln(section.trim());
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayContent = _isLoading ? '' : _parseContent(_rawContent, context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context).generalConditions),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A1A2E),
                          Color(0xFF16213E),
                          Color(0xFF0F0F23)
                        ],
                      )
                    : null,
                color: isDark ? null : Colors.grey[50],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E30) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    displayContent,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
