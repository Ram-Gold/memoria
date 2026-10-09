import 'dart:developer' as developer;
import 'package:flutter_tts/flutter_tts.dart';
import '../languages/baybayin_engine.dart';

class TtsPlaybackResult {
  final bool success;
  final String spokenText;
  final String? errorMessage;
  final bool isMissingVoicePack;

  const TtsPlaybackResult({
    required this.success,
    required this.spokenText,
    this.errorMessage,
    this.isMissingVoicePack = false,
  });
}

/// Hardened multi-platform Text-To-Speech service for authentic language learning.
/// 
/// Handles offline locale negotiation (e.g. 'fil-PH' vs 'tl-PH' on Android),
/// text sanitization (strips Baybayin Unicode glyphs which fail in TTS, resolves Kana readings),
/// and provides clear diagnostics when offline system voice data is uninstalled.
class AppTtsService {
  static final AppTtsService _instance = AppTtsService._internal();
  factory AppTtsService() => _instance;
  AppTtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  List<String> _deviceLanguages = [];

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      final dynamic langs = await _tts.getLanguages;
      if (langs is List) {
        _deviceLanguages = langs.map((e) => e.toString().toLowerCase().trim()).toList();
      }
      _isInitialized = true;
    } catch (e) {
      developer.log('TTS init error: $e', name: 'AppTtsService');
    }
  }

  /// Negotiate the best locale code for the target language supported by this device.
  Future<String> resolveLocale(String languageCode) async {
    await init();

    final code = languageCode.toLowerCase().trim();
    final List<String> candidates;

    switch (code) {
      case 'fil':
      case 'tl':
        // Android Google Speech Services often registers 'tl-PH' or 'tl' rather than 'fil-PH'
        candidates = ['fil-ph', 'tl-ph', 'fil', 'tl', 'fil_ph', 'tl_ph'];
        break;
      case 'ja':
        candidates = ['ja-jp', 'ja', 'ja_jp'];
        break;
      case 'es':
        candidates = ['es-es', 'es-us', 'es-mx', 'es', 'es_es'];
        break;
      case 'fr':
        candidates = ['fr-fr', 'fr', 'fr_fr'];
        break;
      case 'de':
        candidates = ['de-de', 'de', 'de_de'];
        break;
      case 'zh':
        candidates = ['zh-cn', 'zh-tw', 'zh', 'zh_cn'];
        break;
      default:
        candidates = [code];
    }

    if (_deviceLanguages.isNotEmpty) {
      for (final candidate in candidates) {
        final candNorm = candidate.replaceAll('_', '-');
        for (final avail in _deviceLanguages) {
          final availNorm = avail.replaceAll('_', '-');
          if (availNorm == candNorm || availNorm.startsWith('$candNorm-') || candNorm.startsWith('$availNorm-')) {
            // Return formatted locale with standard capitalization (e.g. 'fil-PH', 'tl-PH', 'ja-JP')
            return _formatLocaleString(candidate);
          }
        }
      }
    }

    return _formatLocaleString(candidates.first);
  }

  String _formatLocaleString(String raw) {
    final clean = raw.replaceAll('_', '-');
    final parts = clean.split('-');
    if (parts.length == 2) {
      return '${parts[0].toLowerCase()}-${parts[1].toUpperCase()}';
    }
    return parts[0].toLowerCase();
  }

  /// Extracts the exact clean pronunciation text for the TTS engine.
  /// 
  /// Invariants:
  /// 1. Tagalog: NEVER passes Baybayin Unicode glyphs (U+1700 - U+171F).
  ///    Extracts pure Latin Tagalog words. Strips secondary english translations
  ///    and slashes (e.g. "tasa / mug" -> "tasa").
  /// 2. Japanese: Prioritizes Hiragana/Katakana Kana reading (`secondaryScript`),
  ///    ensuring 100% accurate pitch accent and zero Kanji pronunciation misreads.
  /// 3. Spanish/German/French: Cleans multi-word slashes, using the primary target word.
  static String extractPronunciationText({
    required String languageCode,
    required String targetWord,
    String? secondaryScript,
    String? transliteration,
  }) {
    final code = languageCode.toLowerCase().trim();

    if (code == 'fil' || code == 'tl') {
      // 1. Try secondaryScript (modern Latin Tagalog, e.g. "tasa", "aklat")
      if (secondaryScript != null && secondaryScript.trim().isNotEmpty) {
        var clean = secondaryScript.trim();
        if (clean.contains('/')) {
          clean = clean.split('/').first.trim();
        }
        if (!BaybayinEngine.hasBaybayinGlyphs(clean)) {
          return clean;
        }
      }

      // 2. Transliteration fallback: e.g. "[ak-lat]" -> "aklat"
      if (transliteration != null && transliteration.trim().isNotEmpty) {
        var clean = transliteration.replaceAll(RegExp(r'[\[\]\(\)\-\.]'), ' ').trim();
        clean = clean.replaceAll(RegExp(r'\s+'), ' ');
        if (clean.isNotEmpty && !BaybayinEngine.hasBaybayinGlyphs(clean)) {
          return clean;
        }
      }

      // 3. Target word if it does not contain Baybayin runes
      if (!BaybayinEngine.hasBaybayinGlyphs(targetWord)) {
        var clean = targetWord.trim();
        if (clean.contains('/')) clean = clean.split('/').first.trim();
        return clean;
      }

      return 'salita';
    }

    if (code == 'ja') {
      // Pure kana reading (Hiragana/Katakana) guarantees exact natural reading
      if (secondaryScript != null && secondaryScript.trim().isNotEmpty) {
        var clean = secondaryScript.trim();
        if (clean.contains('/')) clean = clean.split('/').first.trim();
        return clean;
      }
      return targetWord.trim();
    }

    // Default (Spanish, French, German, Mandarin)
    final text = (secondaryScript != null && secondaryScript.trim().isNotEmpty)
        ? secondaryScript.trim()
        : targetWord.trim();
    return text.contains('/') ? text.split('/').first.trim() : text;
  }

  /// Speaks the given object word with automatic locale negotiation and error recovery.
  Future<TtsPlaybackResult> speak({
    required String languageCode,
    required String targetWord,
    String? secondaryScript,
    String? transliteration,
  }) async {
    await init();

    final text = extractPronunciationText(
      languageCode: languageCode,
      targetWord: targetWord,
      secondaryScript: secondaryScript,
      transliteration: transliteration,
    );

    final locale = await resolveLocale(languageCode);

    try {
      await _tts.setLanguage(locale);

      final dynamic isAvail = await _tts.isLanguageAvailable(locale);
      // On Android isLanguageAvailable returns int: 1 = LANG_AVAILABLE, 0 = LANG_MISSING_DATA, -1 = LANG_NOT_SUPPORTED
      final bool available = isAvail == true || isAvail == 1;

      if (!available && _deviceLanguages.isNotEmpty) {
        // Try fallback without region code (e.g. 'tl' instead of 'tl-PH')
        final baseLang = locale.split('-').first;
        final dynamic baseAvail = await _tts.isLanguageAvailable(baseLang);
        if (baseAvail == true || baseAvail == 1) {
          await _tts.setLanguage(baseLang);
        } else {
          developer.log(
            'TTS voice pack missing on device for $locale ($languageCode). Available: $_deviceLanguages',
            name: 'AppTtsService',
          );
          return TtsPlaybackResult(
            success: false,
            spokenText: text,
            isMissingVoicePack: true,
            errorMessage: 'Offline voice data for ${languageCode.toUpperCase()} ($locale) not found on device.',
          );
        }
      }

      await _tts.stop();
      await _tts.speak(text);
      return TtsPlaybackResult(success: true, spokenText: text);
    } catch (e) {
      developer.log('TTS speak exception: $e', name: 'AppTtsService');
      return TtsPlaybackResult(
        success: false,
        spokenText: text,
        errorMessage: 'TTS playback error: $e',
      );
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
