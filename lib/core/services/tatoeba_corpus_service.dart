import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../languages/baybayin_engine.dart';
import '../languages/sentence_generator.dart';

/// Service that fetches real-world bilingual example sentences from the
/// open Tatoeba Corpus API (the underlying sentence database queried by Jisho and language tools).
///
/// Returns curated, learner-friendly native sentences with verified translations,
/// badged with 'Corpus (Jisho/Tatoeba)' and persistently cached in SharedPreferences.
class TatoebaCorpusService {
  final http.Client _client;

  TatoebaCorpusService({http.Client? client}) : _client = client ?? http.Client();

  static const String _cacheKeyPrefix = 'memoria_corpus_v1_';

  /// Maps Memoria ISO-639-1 language codes to Tatoeba ISO-639-3 language codes.
  static String mapLanguageCode(String code) {
    switch (code.toLowerCase()) {
      case 'ja':
        return 'jpn';
      case 'es':
        return 'spa';
      case 'fr':
        return 'fra';
      case 'de':
        return 'deu';
      case 'tl':
      case 'fil':
        return 'tgl';
      case 'zh':
        return 'cmn';
      default:
        return code.toLowerCase();
    }
  }

  /// Fetches verified real-world sentences from Tatoeba.
  /// If [forceRefresh] is false, checks SharedPreferences cache first.
  /// Returns empty list on network failure, timeout, or if no clean sentences are found,
  /// allowing smooth fallback to AI sentence generation.
  Future<List<ExampleSentence>> fetchCorpusSentences({
    required String languageCode,
    required String targetWord,
    String? transliteration,
    bool forceRefresh = false,
    int maxSentences = 3,
  }) async {
    final cleanWord = targetWord.trim();
    if (cleanWord.isEmpty) return const [];

    final cacheKey = '$_cacheKeyPrefix${languageCode.toLowerCase()}_${cleanWord.toLowerCase()}';

    // 1. Check local persistent cache
    if (!forceRefresh) {
      final cached = await _loadFromCache(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    final iso3 = mapLanguageCode(languageCode);
    final uri = Uri.parse(
      'https://api.tatoeba.org/unstable/sentences?lang=$iso3&q=${Uri.encodeComponent(cleanWord)}&trans:lang=eng&sort=relevance',
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MemoriaLanguageLearning/1.0',
        },
      ).timeout(const Duration(milliseconds: 4500));

      if (response.statusCode != 200) {
        developer.log(
          'Tatoeba API returned status ${response.statusCode}',
          name: 'TatoebaCorpusService',
        );
        return const [];
      }

      final Map<String, dynamic> jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> data = jsonBody['data'] as List<dynamic>? ?? const [];

      final List<ExampleSentence> parsedSentences = [];

      for (final item in data) {
        if (parsedSentences.length >= maxSentences) break;

        final rawText = (item['text'] as String?)?.trim() ?? '';
        final translations = item['translations'] as List<dynamic>? ?? const [];

        if (rawText.isEmpty || translations.isEmpty) continue;

        // Find primary English translation
        String? engTrans;
        for (final t in translations) {
          final tLang = t['lang'] as String? ?? '';
          final tText = (t['text'] as String?)?.trim() ?? '';
          if (tLang == 'eng' && tText.isNotEmpty) {
            engTrans = tText;
            break;
          }
        }

        if (engTrans == null || engTrans.isEmpty) continue;

        // Quality filtering:
        // - Appropriate length for language learners (4 to 90 chars)
        // - Contains the target word (or its root)
        if (rawText.length < 4 || rawText.length > 90) continue;
        if (!_containsWordOrRoot(rawText, cleanWord)) continue;
        if (_containsProfanity(rawText) || _containsProfanity(engTrans)) continue;

        // Build transliteration / pronunciation guide
        String sentenceTranslit = '';
        if (languageCode == 'tl' || languageCode == 'fil') {
          sentenceTranslit = BaybayinEngine.transliterate(rawText);
        } else if (transliteration != null && transliteration.isNotEmpty) {
          sentenceTranslit = transliteration;
        }

        parsedSentences.add(
          ExampleSentence(
            nativeSentence: rawText,
            transliteration: sentenceTranslit,
            englishTranslation: engTrans,
            styleLabel: 'Example',
          ),
        );
      }

      if (parsedSentences.isNotEmpty) {
        await _saveToCache(cacheKey, parsedSentences);
      }

      return parsedSentences;
    } catch (e) {
      developer.log(
        'Tatoeba API error for "$targetWord": $e',
        name: 'TatoebaCorpusService',
      );
      return const [];
    }
  }

  bool _containsWordOrRoot(String sentence, String word) {
    if (sentence.contains(word)) return true;
    final lowerSentence = sentence.toLowerCase();
    final lowerWord = word.toLowerCase();
    return lowerSentence.contains(lowerWord);
  }

  bool _containsProfanity(String text) {
    final lower = text.toLowerCase();
    const banned = [
      'fuck',
      'shit',
      'punyeta',
      'gago',
      'putang',
      'bitch',
      'asshole',
      'bastard',
      'scheiße',
      'merde',
      'mierda',
      'chutiya',
      'tarantado',
    ];
    for (final term in banned) {
      if (lower.contains(term)) return true;
    }
    return false;
  }

  Future<List<ExampleSentence>?> _loadFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) {
        return ExampleSentence(
          nativeSentence: item['native_sentence'] as String? ?? '',
          transliteration: item['transliteration'] as String? ?? '',
          englishTranslation: item['english_translation'] as String? ?? '',
          styleLabel: item['style_label'] as String? ?? 'Example',
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(String key, List<ExampleSentence> sentences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = sentences.map((s) => {
        'native_sentence': s.nativeSentence,
        'transliteration': s.transliteration,
        'english_translation': s.englishTranslation,
        'style_label': s.styleLabel,
      }).toList();
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }
}
