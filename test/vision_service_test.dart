import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/language_profile.dart';
import 'package:memoria/data/services/mock_vision_service.dart';

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
      expect(primary!.targetWord, 'マグカップ');
      expect(primary.secondaryScript, 'まぐかっぷ');
      expect(primary.transliteration, 'magukappu');
    });
  });
}
