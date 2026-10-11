import '../languages/baybayin_engine.dart';
import '../../domain/models/detected_object.dart';

/// Represents the two lines of calligraphic/phonetic text rendered on a Polaroid chin.
class ChinText {
  /// Line 1: Target word in native script with English meaning in parentheses.
  /// Example: "猫 (Cat)", "ᜀᜃ᜔ᜎᜆ᜔ (Book)", "书 (Book)"
  final String line1;

  /// Line 2: Pronunciation guide in parentheses.
  /// Example: "(neko)", "(aklat · [ak-lat])", "(shū)"
  final String line2;

  const ChinText({
    required this.line1,
    required this.line2,
  });

  @override
  String toString() => 'ChinText(line1: "$line1", line2: "$line2")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChinText &&
          runtimeType == other.runtimeType &&
          line1 == other.line1 &&
          line2 == other.line2;

  @override
  int get hashCode => line1.hashCode ^ line2.hashCode;
}

/// Centralized utility for consistent Polaroid chin text formatting across
/// capture reveal, editor screen, hero gallery views, and album thumbnails.
class ChinFormatHelper {
  /// Formats the detected object and language code into standardized Line 1 & Line 2 chin text.
  static ChinText format({
    required String targetWord,
    String? secondaryScript,
    String? transliteration,
    String? labelEn,
    required String languageCode,
  }) {
    final cleanMeaning = _formatMeaning(labelEn);
    final trimmedWord = targetWord.trim();
    final lang = languageCode.trim().toLowerCase();

    // 1. Build Line 1: [Native Script] ([Meaning])
    final line1 = cleanMeaning.isNotEmpty
        ? '$trimmedWord ($cleanMeaning)'
        : trimmedWord;

    // 2. Build Line 2: ([Pronunciation])
    final line2 = _formatLine2(
      lang: lang,
      targetWord: trimmedWord,
      secondaryScript: secondaryScript?.trim(),
      transliteration: transliteration?.trim(),
    );

    return ChinText(line1: line1, line2: line2);
  }

  /// Convenience wrapper that formats directly from a [DetectedObject].
  static ChinText formatFromObject(DetectedObject obj, String languageCode) {
    return format(
      targetWord: obj.targetWord,
      secondaryScript: obj.secondaryScript,
      transliteration: obj.transliteration,
      labelEn: obj.labelEn,
      languageCode: languageCode,
    );
  }

  /// Formats Line 2 based on language-specific transliteration standards.
  static String _formatLine2({
    required String lang,
    required String targetWord,
    String? secondaryScript,
    String? transliteration,
  }) {
    final cleanTranslit = _stripOuterParentheses(transliteration);
    final cleanSecondary = _stripOuterParentheses(secondaryScript);

    if (lang == 'ja') {
      // Japanese: (Romaji) e.g. (neko), (hon), (koppu)
      if (cleanTranslit.isNotEmpty) {
        return '($cleanTranslit)';
      }
      if (cleanSecondary.isNotEmpty) {
        return '($cleanSecondary)';
      }
      return '';
    }

    if (lang == 'fil' || lang == 'tl') {
      // Filipino / Baybayin: (Latin Tagalog · [pronunciation])
      // e.g. (aklat · [ak-lat]) or (pusa · [pu-sa])
      final tagalogWord = cleanSecondary.isNotEmpty
          ? cleanSecondary
          : (!BaybayinEngine.hasBaybayinGlyphs(targetWord) ? targetWord : '');

      String phonetic = cleanTranslit;
      if (phonetic.isEmpty && tagalogWord.isNotEmpty) {
        phonetic = BaybayinEngine.formatPronunciation(tagalogWord);
      } else if (phonetic.isNotEmpty && !phonetic.startsWith('[')) {
        phonetic = '[$phonetic]';
      }

      if (tagalogWord.isNotEmpty && phonetic.isNotEmpty) {
        return '($tagalogWord · $phonetic)';
      } else if (tagalogWord.isNotEmpty) {
        return '($tagalogWord)';
      } else if (phonetic.isNotEmpty) {
        return '($phonetic)';
      }
      return '';
    }

    if (lang == 'zh' || lang.startsWith('zh-')) {
      // Chinese: (Pinyin with tones) e.g. (shū), (māo)
      if (cleanTranslit.isNotEmpty) {
        return '($cleanTranslit)';
      }
      if (cleanSecondary.isNotEmpty) {
        return '($cleanSecondary)';
      }
      return '';
    }

    // Default / Tier 2 languages (Spanish, French, German, etc.)
    final guide = cleanTranslit.isNotEmpty
        ? cleanTranslit
        : (cleanSecondary.isNotEmpty ? cleanSecondary : '');
    return guide.isNotEmpty ? '($guide)' : '';
  }

  /// Cleans and title-cases the English meaning label.
  /// Rejects generic placeholders like "item" or "object".
  static String _formatMeaning(String? label) {
    if (label == null || label.trim().isEmpty) return '';
    final trimmed = label.trim();
    final lower = trimmed.toLowerCase();
    if (lower == 'item' || lower == 'object' || lower == 'default' || lower == 'unknown') {
      return '';
    }

    // Title case words (e.g. "coffee mug" -> "Coffee Mug")
    return trimmed.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Strips leading and trailing parentheses or brackets if the AI already included them.
  static String _stripOuterParentheses(String? text) {
    if (text == null) return '';
    var s = text.trim();
    if (s.startsWith('(') && s.endsWith(')')) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }
}
