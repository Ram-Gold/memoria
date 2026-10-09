import 'dart:typed_data';
import '../../core/languages/baybayin_engine.dart';
import '../../core/languages/language_profile.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/services/vision_service.dart';

class MockVisionService implements VisionService {
  @override
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    required LanguageProfile language,
  }) async {
    // Simulate real AI processing latency (2.5s)
    await Future.delayed(const Duration(milliseconds: 2500));

    final sessionId = 'mem_mock_${DateTime.now().millisecondsSinceEpoch}';

    if (language.code == 'fil') {
      return AnalysisResult(
        sessionId: sessionId,
        languageCode: 'fil',
        primaryObjectId: 'obj_01',
        sceneDescription: 'A study desk with an open book, coffee mug, and notebook',
        detectedObjects: [
          DetectedObject(
            id: 'obj_01',
            labelEn: 'Book',
            targetWord: BaybayinEngine.transliterate('aklat'), // ᜀᜃ᜔ᜎᜆ᜔
            secondaryScript: 'aklat',
            transliteration: '[ak-lat]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            box: const [150, 180, 820, 750],
          ),
          DetectedObject(
            id: 'obj_02',
            labelEn: 'Coffee Mug',
            targetWord: BaybayinEngine.transliterate('tasa'), // ᜆᜐ
            secondaryScript: 'tasa',
            transliteration: '[ta-sa]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            box: const [480, 720, 850, 930],
          ),
          DetectedObject(
            id: 'obj_03',
            labelEn: 'Desk',
            targetWord: BaybayinEngine.transliterate('mesa'), // ᜋᜒᜐ
            secondaryScript: 'mesa',
            transliteration: '[me-sa]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A2',
            box: const [50, 50, 950, 950],
          ),
        ],
      );
    } else if (language.code == 'ja') {
      return AnalysisResult(
        sessionId: sessionId,
        languageCode: 'ja',
        primaryObjectId: 'obj_01',
        sceneDescription: 'Sunlit wooden table with a ceramic coffee mug and notebook',
        detectedObjects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Coffee Mug',
            targetWord: 'マグカップ',
            secondaryScript: 'まぐかっぷ',
            transliteration: 'magukappu',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            box: [480, 720, 850, 930],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Book',
            targetWord: '本',
            secondaryScript: 'ほん',
            transliteration: 'hon',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            box: [150, 180, 820, 750],
          ),
          const DetectedObject(
            id: 'obj_03',
            labelEn: 'Desk',
            targetWord: '机',
            secondaryScript: 'つくえ',
            transliteration: 'tsukue',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            box: [50, 50, 950, 950],
          ),
        ],
      );
    } else {
      // Generic language profile fallback (e.g. Spanish)
      return AnalysisResult(
        sessionId: sessionId,
        languageCode: language.code,
        primaryObjectId: 'obj_01',
        sceneDescription: 'Desk scene with common study items',
        detectedObjects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Book',
            targetWord: 'Libro',
            secondaryScript: 'el libro',
            transliteration: '[lee-bro]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            box: [150, 180, 820, 750],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Cup',
            targetWord: 'Taza',
            secondaryScript: 'la taza',
            transliteration: '[tah-sah]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            box: [480, 720, 850, 930],
          ),
        ],
      );
    }
  }
}
