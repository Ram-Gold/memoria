import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/languages/baybayin_engine.dart';
import '../../core/languages/language_profile.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/services/vision_service.dart';
import 'mock_vision_service.dart';

class MistralVisionService implements VisionService {
  final String apiKey;
  final String model;
  final MockVisionService _fallbackService = MockVisionService();

  MistralVisionService({
    required this.apiKey,
    this.model = 'pixtral-12b-2409',
  });

  @override
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    required LanguageProfile language,
  }) async {
    if (apiKey.trim().isEmpty) {
      developer.log('Mistral API key is empty, using MockVisionService fallback', name: 'MistralVisionService');
      return _fallbackService.analyze(imageBytes: imageBytes, language: language);
    }

    try {
      final base64Image = base64Encode(imageBytes);
      final systemPrompt = '''
You are Memoria's Core Vision & Lexicon Agent for language learning.
Analyze the photograph and generate structured vocabulary for an analog Polaroid print.

CRITICAL INVARIANTS:
1. Identify 1 to 5 prominent tangible physical objects in the image. Reject human identity / faces (no PII).
2. Select exactly ONE primary focal object ('primary_object_id').
3. Keep labels concise (1-2 words).
4. Always choose the most common beginner-friendly everyday word (e.g. A1 / N5 level).
5. ${language.promptInstructions}
6. Provide a concise scene_description (max 80 chars).
7. Normalized bounding box coordinates must follow [ymin, xmin, ymax, xmax] on a scale of 0 to 1000.

OUTPUT FORMAT:
Return pure valid JSON conforming strictly to this format:
{
  "session_id": "mem_${DateTime.now().millisecondsSinceEpoch}",
  "language_code": "${language.code}",
  "primary_object_id": "obj_01",
  "scene_description": "short description of the scene",
  "detected_objects": [
    {
      "id": "obj_01",
      "label_en": "object label in English",
      "target_word": "native script target word",
      "secondary_script": "secondary script or reading",
      "transliteration": "pronunciation or romaji",
      "part_of_speech": "Noun",
      "difficulty_level": "A1 or N5",
      "box_2d": [100, 100, 800, 800]
    }
  ]
}
''';

      final url = Uri.parse('https://api.mistral.ai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': systemPrompt},
                {
                  'type': 'image_url',
                  'image_url': 'data:image/jpeg;base64,$base64Image',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        developer.log('Mistral API error (${response.statusCode}): ${response.body}', name: 'MistralVisionService');
        // Fallback to mock on API error so the user is never stranded
        return _fallbackService.analyze(imageBytes: imageBytes, language: language);
      }

      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content']?.toString() ?? '{}';
      final parsedJson = jsonDecode(content) as Map<String, dynamic>;

      var result = AnalysisResult.fromJson(parsedJson);

      // Post-processing hybrid validation for Filipino Baybayin
      if (language.code == 'fil') {
        final verifiedObjects = result.detectedObjects.map((obj) {
          String baybayin = obj.targetWord;
          // If the AI didn't output Baybayin glyphs or slipped, generate using deterministic engine
          if (!BaybayinEngine.hasBaybayinGlyphs(baybayin)) {
            final sourceTagalog = obj.secondaryScript ?? obj.labelEn;
            baybayin = BaybayinEngine.transliterate(sourceTagalog);
          }
          return obj.copyWith(targetWord: baybayin);
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
      developer.log('Error in MistralVisionService: $e', error: e, stackTrace: stack, name: 'MistralVisionService');
      return _fallbackService.analyze(imageBytes: imageBytes, language: language);
    }
  }
}
