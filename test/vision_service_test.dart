import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/language_profile.dart';
import 'package:memoria/data/services/gemini_vision_service.dart';
import 'package:memoria/data/services/mock_vision_service.dart';
import 'package:memoria/domain/models/analysis_result.dart';

void main() {
  group('VisionService Tests', () {
    final mockService = MockVisionService();
    final dummyBytes = Uint8List(10);

    test('mock analysis for Filipino returns Baybayin and scene description', () async {
      final result = await mockService.analyze(
        imageBytes: dummyBytes,
        language: LanguageRegistry.filipino,
      );

      expect(result.languageCode, 'fil');
      expect(result.sceneDescription, isNotEmpty);
      expect(result.detectedObjects, isNotEmpty);

      final primary = result.primaryObject;
      expect(primary, isNotNull);
      expect(primary!.targetWord, isNotEmpty);
      expect(primary.secondaryScript, isNotEmpty);
      expect(primary.transliteration, isNotEmpty);
    });

    test('mock analysis for Japanese returns Kanji and Hiragana reading', () async {
      final result = await mockService.analyze(
        imageBytes: dummyBytes,
        language: LanguageRegistry.japanese,
      );

      expect(result.languageCode, 'ja');
      expect(result.sceneDescription, isNotEmpty);
      expect(result.detectedObjects, isNotEmpty);

      final primary = result.primaryObject;
      expect(primary, isNotNull);
      expect(primary!.targetWord, isNotEmpty);
      expect(primary.secondaryScript, isNotEmpty);
      expect(primary.transliteration, isNotEmpty);
    });

    test('GeminiVisionService defaults to gemini-2.0-flash and falls back when apiKey is empty', () async {
      final geminiService = GeminiVisionService(apiKey: '');
      expect(geminiService.model, 'gemini-2.0-flash');

      final result = await geminiService.analyze(
        imageBytes: dummyBytes,
        language: LanguageRegistry.japanese,
      );

      expect(result.languageCode, 'ja');
      expect(result.detectedObjects, isNotEmpty);
      expect(result.primaryObject, isNotNull);
    });

    test('AnalysisResult accurately deserializes Gemini structured schema format', () {
      final geminiSampleJson = {
        'session_id': 'mem_test_123',
        'language_code': 'ja',
        'primary_object_id': 'obj_01',
        'scene_description': 'A ceramic mug on a wooden cafe desk',
        'detected_objects': [
          {
            'id': 'obj_01',
            'label_en': 'mug',
            'target_word': 'マグカップ',
            'secondary_script': 'まぐかっぷ',
            'transliteration': 'magukappu',
            'part_of_speech': 'Noun',
            'difficulty_level': 'N5',
            'confidence': 0.96,
            'box_2d': [120, 250, 780, 890],
          },
          {
            'id': 'obj_02',
            'label_en': 'desk',
            'target_word': '机',
            'secondary_script': 'つくえ',
            'transliteration': 'tsukue',
            'part_of_speech': 'Noun',
            'difficulty_level': 'N5',
            'confidence': 0.88,
            'box_2d': [450, 50, 950, 950],
          }
        ],
      };

      final result = AnalysisResult.fromJson(geminiSampleJson);
      expect(result.sessionId, 'mem_test_123');
      expect(result.languageCode, 'ja');
      expect(result.primaryObjectId, 'obj_01');
      expect(result.sceneDescription, 'A ceramic mug on a wooden cafe desk');
      expect(result.detectedObjects.length, 2);

      final primary = result.primaryObject;
      expect(primary, isNotNull);
      expect(primary!.id, 'obj_01');
      expect(primary.labelEn, 'mug');
      expect(primary.targetWord, 'マグカップ');
      expect(primary.secondaryScript, 'まぐかっぷ');
      expect(primary.transliteration, 'magukappu');
      expect(primary.confidence, 0.96);
      expect(primary.box, [120, 250, 780, 890]);
    });
  });
}
