import 'package:flutter/material.dart';

class LegalHelper {
  // We no longer need to parse raw content if we use the maps in LegalContent
  // But to keep API compatibility, we might still accept rawContent (though ignore it if we just use the static maps).
  // However, the existing calls pass "rawContent" which is loaded from assets/terms.txt.
  // The user wants to "Hard code em".

  // Best approach: Modals pass a KEY or we inspect the content to decide?
  // Actually, the callers (screens) are loading the file content then passing it here.
  // If we want to fully hardcode, we should change the SCREENS to pass a KEY or just not load files at all.

  // But to minimize changes in 4+ files, we can just deduce which content was requested?
  // Or simpler: Update `extractLanguageSection` to be `getContent(LegalType type, BuildContext context)` and refactor callers.

  // Let's refactor the method signature to take a map, or just static keys.
  // Since we have 3 types: Terms, Privacy, General Conditions.

  static String getLocalizedContent(
    BuildContext context,
    Map<String, String> contentMap,
  ) {
    final locale = Localizations.localeOf(context);
    final isFrench = locale.languageCode == 'fr';

    // Default to EN if not FR
    return isFrench ? (contentMap['fr'] ?? '') : (contentMap['en'] ?? '');
  }

  // Deprecated shim if needed, but better to refactor callers.
  // We will refactor callers to use getLocalizedContent(context, LegalContent.terms) etc.
}
