import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/languages/baybayin_engine.dart';
import '../../core/languages/language_profile.dart';
import '../../core/services/tagalog_dictionary_service.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/services/vision_service.dart';
import 'mock_vision_service.dart';

/// Vision service implementation for Google Gemini (e.g. gemini-2.0-flash / gemini-1.5-flash with strict JSON schema).
/// 
/// Leverages Google's fixed 258 image token pricing ($0.00002/call or free tier) and native responseSchema
/// for 100% type-safe JSON extraction without markdown fencing or format drift.
class GeminiVisionService implements VisionService {
  final String apiKey;
  final String model;
  final MockVisionService _fallbackService = MockVisionService();

  GeminiVisionService({
    required this.apiKey,
    this.model = 'gemini-2.0-flash',
  });

  static const Map<String, dynamic> _geminiResponseSchema = {
    'type': 'OBJECT',
    'properties': {
      'session_id': {'type': 'STRING'},
      'language_code': {'type': 'STRING'},
      'primary_object_id': {'type': 'STRING'},
      'scene_description': {'type': 'STRING'},
      'detected_objects': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'id': {'type': 'STRING'},
            'label_en': {'type': 'STRING'},
            'target_word': {'type': 'STRING'},
            'secondary_script': {'type': 'STRING'},
            'transliteration': {'type': 'STRING'},
            'part_of_speech': {'type': 'STRING'},
            'difficulty_level': {'type': 'STRING'},
            'confidence': {'type': 'NUMBER'},
            'box_2d': {
              'type': 'ARRAY',
              'items': {'type': 'INTEGER'},
            },
          },
          'required': [
            'id',
            'label_en',
            'target_word',
            'transliteration',
            'part_of_speech',
            'difficulty_level',
            'confidence',
            'box_2d',
          ],
        },
      },
    },
    'required': [
      'session_id',
      'language_code',
      'primary_object_id',
      'scene_description',
      'detected_objects',
    ],
  };

  @override
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    required LanguageProfile language,
  }) async {
    if (apiKey.trim().isEmpty) {
      developer.log(
        'Gemini API key is empty, using MockVisionService fallback',
        name: 'GeminiVisionService',
      );
      return _fallbackService.analyze(imageBytes: imageBytes, language: language);
    }

    try {
      final base64Image = base64Encode(imageBytes);
      final systemPrompt = '''
You are Memoria's Core Vision & Lexicon Agent for language learning.
Analyze the photograph and generate structured vocabulary for an analog Polaroid print.

CRITICAL INVARIANTS:
1. Identify 1 to 5 prominent tangible physical objects in the image. Reject human identity / faces (no PII).
2. Select exactly ONE primary focal object ('primary_object_id') that best represents the photograph's main subject.
3. For each object, assign a confidence score between 0.0 and 1.0 (e.g. 0.95 for clearly recognized objects).
4. Keep labels concise (1-2 words).
5. Pedagogical Rule: Always choose the most common beginner-friendly everyday word (e.g. A1 / N5 level). For example in Japanese, prefer マグカップ or コップ rather than archaic 珈琲碗. In Filipino, prefer common terms (e.g. aklat, mesa, baso).
6. ${language.promptInstructions}
7. Provide a concise scene_description (max 80 chars).
8. Normalized bounding box coordinates must follow [ymin, xmin, ymax, xmax] on a scale of 0 to 1000 representing each object's exact location.
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${apiKey.trim()}',
      );

      final requestBody = jsonEncode({
        'generationConfig': {
          'responseMimeType': 'application/json',
          'responseSchema': _geminiResponseSchema,
        },
        'contents': [
          {
            'parts': [
              {'text': systemPrompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
            ],
          },
        ],
      });

      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      // If the model or endpoint rejected responseSchema (e.g. older endpoints), retry with responseMimeType only
      if (response.statusCode == 400 && response.body.contains('responseSchema')) {
        developer.log('responseSchema rejected by model, retrying with responseMimeType only', name: 'GeminiVisionService');
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'generationConfig': {
              'responseMimeType': 'application/json',
            },
            'contents': [
              {
                'parts': [
                  {'text': systemPrompt},
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
          }),
        );
      }

      if (response.statusCode != 200) {
        developer.log('Gemini API error (${response.statusCode}): ${response.body}', name: 'GeminiVisionService');
        return _fallbackService.analyze(imageBytes: imageBytes, language: language);
      }

      final data = jsonDecode(response.body);
      final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString() ?? '{}';
      
      // Clean possible markdown fencing
      String cleanedJson = rawText.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.replaceFirst('```json', '');
      }
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.replaceFirst('```', '');
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      final parsedJson = jsonDecode(cleanedJson) as Map<String, dynamic>;
      var result = AnalysisResult.fromJson(parsedJson);

      // Post-processing hybrid validation for Filipino Baybayin
      if (language.code == 'fil') {
        final verifiedObjects = result.detectedObjects.map((obj) {
          final dictEntry = TagalogDictionaryService.instance.lookupByEnglish(obj.labelEn);
          final tagalogWord = dictEntry?.word ??
              (obj.secondaryScript != null && obj.secondaryScript!.trim().isNotEmpty
                  ? obj.secondaryScript!.trim().toLowerCase()
                  : obj.labelEn.trim().toLowerCase());

          final baybayin = BaybayinEngine.transliterate(tagalogWord);
          final pronunciation = (obj.transliteration != null && obj.transliteration!.startsWith('['))
              ? obj.transliteration!
              : BaybayinEngine.formatPronunciation(tagalogWord);

          return obj.copyWith(
            targetWord: baybayin,
            secondaryScript: tagalogWord,
            transliteration: pronunciation,
          );
        }).toList();

        result = AnalysisResult(
          sessionId: result.sessionId,
          languageCode: result.languageCode,
          primaryObjectId: result.primaryObjectId,
          sceneDescription: result.sceneDescription,
          detectedObjects: verifiedObjects,
        );
      }

      return result;
    } catch (e, stack) {
      developer.log('Error in GeminiVisionService: $e', error: e, stackTrace: stack, name: 'GeminiVisionService');
      return _fallbackService.analyze(imageBytes: imageBytes, language: language);
    }
  }
}
