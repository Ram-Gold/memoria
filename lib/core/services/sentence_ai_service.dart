import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../languages/sentence_generator.dart';

/// Service that dynamically generates authentic, context-aware example sentences
/// via Gemini Vision/Language models with structured JSON output and local offline caching.
class SentenceAiService {
  final http.Client _client;

  SentenceAiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _cacheKeyPrefix = 'memoria_ai_sentences_v1_';

  /// Generates dynamic contextual sentences using Gemini.
  /// If [forceRefresh] is false, checks SharedPreferences cache first.
  /// Falls back to [SentenceGeneratorService.generate] if no API key or network fails.
  Future<List<ExampleSentence>> generateSentences({
    required String apiKey,
    required String languageCode,
    required String targetWord,
    required String labelEn,
    String? secondaryScript,
    String? transliteration,
    String? sceneDescription,
    String model = 'gemini-2.0-flash',
    bool forceRefresh = false,
  }) async {
    final cleanWord = targetWord.trim();
    final cacheKey = '$_cacheKeyPrefix${languageCode.toLowerCase()}_${cleanWord.toLowerCase()}';

    // 1. Check local persistent cache if not forcing refresh
    if (!forceRefresh) {
      final cached = await _loadFromCache(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    // 2. If API key is empty, return enhanced offline fallback
    if (apiKey.trim().isEmpty) {
      return SentenceGeneratorService.generate(
        languageCode: languageCode,
        targetWord: targetWord,
        labelEn: labelEn,
        secondaryScript: secondaryScript,
        transliteration: transliteration,
      );
    }

    // 3. Call Gemini API with structured JSON
    try {
      final prompt = _buildPrompt(
        languageCode: languageCode,
        targetWord: targetWord,
        labelEn: labelEn,
        secondaryScript: secondaryScript,
        transliteration: transliteration,
        sceneDescription: sceneDescription,
      );

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${apiKey.trim()}',
      );

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'nativeSentence': {'type': 'STRING'},
                  'transliteration': {'type': 'STRING'},
                  'englishTranslation': {'type': 'STRING'},
                  'styleLabel': {'type': 'STRING'},
                },
                'required': [
                  'nativeSentence',
                  'transliteration',
                  'englishTranslation',
                  'styleLabel',
                ],
              },
            },
          },
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = jsonBody['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates.first['content']['parts'] as List;
          final text = parts.first['text'] as String;
          final parsed = jsonDecode(text) as List;

          final results = parsed.map((item) {
            final map = item as Map<String, dynamic>;
            return ExampleSentence(
              nativeSentence: map['nativeSentence'] as String,
              transliteration: map['transliteration'] as String? ?? '',
              englishTranslation: map['englishTranslation'] as String,
              styleLabel: map['styleLabel'] as String? ?? 'In Context',
            );
          }).toList();

          if (results.isNotEmpty) {
            await _saveToCache(cacheKey, results);
            return results;
          }
        }
      } else {
        developer.log(
          'Gemini sentence generation error: ${response.statusCode} - ${response.body}',
          name: 'SentenceAiService',
        );
      }
    } catch (e) {
      developer.log(
        'SentenceAiService request error: $e',
        name: 'SentenceAiService',
      );
    }

    // Fallback to offline rule-based generator
    return SentenceGeneratorService.generate(
      languageCode: languageCode,
      targetWord: targetWord,
      labelEn: labelEn,
      secondaryScript: secondaryScript,
      transliteration: transliteration,
    );
  }

  static String _buildPrompt({
    required String languageCode,
    required String targetWord,
    required String labelEn,
    String? secondaryScript,
    String? transliteration,
    String? sceneDescription,
  }) {
    return '''
You are an expert linguistics pedagogue for Memoria, a language learning Polaroid app.
Generate exactly 2 natural, culturally authentic, and grammatically flawless example sentences demonstrating the vocabulary word "$targetWord" ($labelEn) in context.

Target Language: $languageCode
${secondaryScript != null && secondaryScript.isNotEmpty ? 'Secondary Script: $secondaryScript' : ''}
${transliteration != null && transliteration.isNotEmpty ? 'Transliteration: $transliteration' : ''}
${sceneDescription != null && sceneDescription.isNotEmpty ? 'Photograph Scene Context: $sceneDescription' : ''}

CRITICAL RULES:
1. Grammatical Precision: Ensure 100% accurate gender agreement, noun declension, and particles in the target language. NEVER use generic slotting like "on the table" unless it genuinely fits.
2. Natural Idiomatic Usage: Sentences must sound like authentic native speech in everyday life or conversation.
3. Transliteration / Pronunciation Guide:
   - Japanese: Hepburn Romaji.
   - Mandarin: Pinyin with tone marks.
   - Filipino: Syllable pronunciation guide (e.g. [Ma-gan-dang a-raw]).
   - Spanish/French/German: Phonetic pronunciation assistance.
4. Style Labels: Provide a short, expressive label (e.g. "Everyday Conversation", "At the Cafe", "Expressive", "Daily Routine").
''';
  }

  Future<List<ExampleSentence>?> _loadFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return ExampleSentence(
          nativeSentence: m['native'] as String,
          transliteration: m['translit'] as String? ?? '',
          englishTranslation: m['en'] as String,
          styleLabel: m['style'] as String? ?? 'Example',
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(String key, List<ExampleSentence> sentences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = sentences
          .map((s) => {
                'native': s.nativeSentence,
                'translit': s.transliteration,
                'en': s.englishTranslation,
                'style': s.styleLabel,
              })
          .toList();
      await prefs.setString(key, jsonEncode(list));
    } catch (_) {}
  }
}
