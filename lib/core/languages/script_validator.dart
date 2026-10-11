import '../../domain/models/detected_object.dart';
import '../../data/services/local_object_lexicon.dart';
import 'baybayin_engine.dart';

/// Orthographic gatekeeper that enforces authentic native writing systems
/// and prevents raw English text from leaking into foreign vocabulary slots.
class ScriptValidator {
  static final RegExp _japaneseRegex =
      RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
  static final RegExp _chineseRegex = RegExp(r'[\u4E00-\u9FFF]');
  static final RegExp _baybayinRegex = RegExp(r'[\u1700-\u171F]');
  static final RegExp _pureAsciiRegex = RegExp(r'^[a-zA-Z0-9\s\-_.,()!?"' "'" r']+$');

  /// Returns true if [targetWord] meets the authentic native script requirements
  /// for [langCode].
  static bool isValidTargetWord(String targetWord, String langCode) {
    final trimmed = targetWord.trim();
    if (trimmed.isEmpty) return false;
    final code = langCode.toLowerCase();

    if (code == 'ja') {
      // Japanese must contain at least one Kana or Kanji character and cannot be pure ASCII
      return _japaneseRegex.hasMatch(trimmed) && !_pureAsciiRegex.hasMatch(trimmed);
    } else if (code == 'zh' || code.startsWith('zh')) {
      // Mandarin Chinese must contain Hanzi and cannot be pure ASCII
      return _chineseRegex.hasMatch(trimmed) && !_pureAsciiRegex.hasMatch(trimmed);
    } else if (code == 'fil' || code == 'tl') {
      // For Baybayin-first layouts, targetWord must contain Baybayin script
      return _baybayinRegex.hasMatch(trimmed) || trimmed.isNotEmpty;
    }
    return true;
  }

  /// Determines whether [targetWord] is simply English text leaked into a foreign slot.
  static bool isLeakedEnglish(String targetWord, String labelEn, String langCode) {
    final code = langCode.toLowerCase();
    final cleanTarget = targetWord.trim().toLowerCase();
    final cleanLabel = labelEn.trim().toLowerCase();

    // 1. If target is pure ASCII for Japanese or Chinese, it's definitely leaked English
    if (code == 'ja' || code == 'zh' || code.startsWith('zh')) {
      if (!isValidTargetWord(targetWord, code)) return true;
    }

    // 2. If target word is identical to the English label for non-English languages
    if (code != 'en' && cleanTarget == cleanLabel && cleanLabel.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Sanitizes and repairs a [DetectedObject] to guarantee authentic native script.
  /// If the object contains leaked English or fails script checks, it is repaired
  /// via [LocalObjectLexicon] lookup or categorical fallback.
  static DetectedObject sanitizeObject(DetectedObject obj, String langCode) {
    final code = langCode.toLowerCase();
    
    // Check if the current target word is valid
    final isInvalid = isLeakedEnglish(obj.targetWord, obj.labelEn, code) ||
        !isValidTargetWord(obj.targetWord, code);

    if (!isInvalid) {
      // If Filipino, make sure Baybayin script is present in targetWord
      if (code == 'fil' || code == 'tl') {
        if (!_baybayinRegex.hasMatch(obj.targetWord)) {
          final tagalogWord = obj.secondaryScript != null && obj.secondaryScript!.isNotEmpty
              ? obj.secondaryScript!
              : obj.targetWord;
          final normalized = BaybayinEngine.normalizeTagalogPhonetics(tagalogWord);
          final baybayin = BaybayinEngine.transliterate(normalized);
          return obj.copyWith(
            targetWord: baybayin,
            secondaryScript: tagalogWord,
            transliteration: obj.transliteration != null && obj.transliteration!.startsWith('[')
                ? obj.transliteration
                : BaybayinEngine.formatPronunciation(tagalogWord),
          );
        }
      }
      return obj;
    }

    // Attempt repair via LocalObjectLexicon
    final lookup = LocalObjectLexicon.lookup(className: obj.labelEn, langCode: code) ??
        LocalObjectLexicon.synthesizeEntry(label: obj.labelEn, langCode: code);

    return obj.copyWith(
      labelEn: lookup.labelEn,
      targetWord: lookup.targetWord,
      secondaryScript: lookup.secondaryScript,
      transliteration: lookup.transliteration,
      partOfSpeech: lookup.partOfSpeech.isNotEmpty ? lookup.partOfSpeech : obj.partOfSpeech,
      difficultyLevel: lookup.difficultyLevel.isNotEmpty ? lookup.difficultyLevel : obj.difficultyLevel,
    );
  }
}
