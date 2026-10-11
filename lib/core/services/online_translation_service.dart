import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../languages/script_validator.dart';

class OnlineTranslationResult {
  final String translatedText;
  final String targetLangCode;

  const OnlineTranslationResult({
    required this.translatedText,
    required this.targetLangCode,
  });
}

/// Lightweight online translation service with caching and timeout guardrails.
/// Used to dynamically resolve unfamiliar or specific object labels when online.
class OnlineTranslationService {
  static final OnlineTranslationService instance = OnlineTranslationService._();
  OnlineTranslationService._();

  // In-memory cache: "langCode:text" -> translatedText
  final Map<String, String> _cache = {};

  /// Translates [englishText] to [targetLangCode].
  /// Returns null if offline, timed out, or if the translated text fails script validation.
  Future<OnlineTranslationResult?> translate({
    required String englishText,
    required String targetLangCode,
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    final clean = englishText.trim();
    if (clean.isEmpty) return null;

    final lang = targetLangCode.toLowerCase();
    // Normalize language codes for translation APIs
    final apiLang = (lang == 'fil') ? 'tl' : lang;

    final cacheKey = '$apiLang:${clean.toLowerCase()}';
    if (_cache.containsKey(cacheKey)) {
      return OnlineTranslationResult(
        translatedText: _cache[cacheKey]!,
        targetLangCode: targetLangCode,
      );
    }

    try {
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(clean)}&langpair=en|$apiLang',
      );

      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final translated = data['responseData']?['translatedText']
            ?.toString()
            .trim();

        if (translated != null && translated.isNotEmpty) {
          // Verify that translated text is valid for the target script
          if (ScriptValidator.isValidTargetWord(translated, targetLangCode) &&
              !ScriptValidator.isLeakedEnglish(
                translated,
                clean,
                targetLangCode,
              )) {
            _cache[cacheKey] = translated;
            return OnlineTranslationResult(
              translatedText: translated,
              targetLangCode: targetLangCode,
            );
          }
        }
      }
    } catch (e) {
      developer.log(
        'Online translation request ignored: $e',
        name: 'OnlineTranslationService',
      );
    }

    return null;
  }
}
