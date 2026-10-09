import 'dart:math';
import 'dart:typed_data';
import '../../core/languages/baybayin_engine.dart';
import '../../core/languages/language_profile.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/services/vision_service.dart';

/// Offline darkroom vision engine that provides diverse, pedagogically sound
/// results sampled dynamically based on image characteristics and session entropy.
class MockVisionService implements VisionService {
  @override
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    required LanguageProfile language,
  }) async {
    // Simulate analog film development latency (1.8s)
    await Future.delayed(const Duration(milliseconds: 1800));

    final sessionId = 'mem_darkroom_${DateTime.now().millisecondsSinceEpoch}';

    // Calculate a hash/seed from the image bytes to vary detected scenes dynamically
    int seed = 0;
    if (imageBytes.isNotEmpty) {
      final sampleStep = max(1, imageBytes.length ~/ 64);
      for (int i = 0; i < imageBytes.length; i += sampleStep) {
        seed = (seed * 31 + imageBytes[i]) & 0x7FFFFFFF;
      }
    } else {
      seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    }

    if (language.code == 'fil') {
      return _generateFilipinoResult(sessionId, seed);
    } else if (language.code == 'ja') {
      return _generateJapaneseResult(sessionId, seed);
    } else {
      return _generateSpanishResult(sessionId, seed, language);
    }
  }

  AnalysisResult _generateJapaneseResult(String sessionId, int seed) {
    // 5 diverse analog scene scenarios
    final scenarios = [
      // Scenario 0: Cozy Cafe / Table
      _SceneData(
        description: 'Sunlit wooden cafe counter with coffee and pastries',
        objects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Coffee Mug',
            targetWord: '珈琲碗',
            secondaryScript: 'コーヒーカップ',
            transliteration: 'koohii kappu',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.95,
            box: [450, 680, 850, 920],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Book',
            targetWord: '本',
            secondaryScript: 'ほん',
            transliteration: 'hon',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.88,
            box: [180, 160, 780, 700],
          ),
          const DetectedObject(
            id: 'obj_03',
            labelEn: 'Desk',
            targetWord: '机',
            secondaryScript: 'つくえ',
            transliteration: 'tsukue',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.52,
            box: [50, 50, 950, 950],
          ),
        ],
      ),
      // Scenario 1: City / Street / Alley
      _SceneData(
        description: 'Quiet residential street corner with bicycle and vending machine',
        objects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Bicycle',
            targetWord: '自転車',
            secondaryScript: 'じてんしゃ',
            transliteration: 'jitensha',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.96,
            box: [320, 210, 880, 790],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Street',
            targetWord: '通り',
            secondaryScript: 'とおり',
            transliteration: 'toori',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N4',
            confidence: 0.82,
            box: [100, 50, 950, 950],
          ),
          const DetectedObject(
            id: 'obj_03',
            labelEn: 'Tree',
            targetWord: '木',
            secondaryScript: 'き',
            transliteration: 'ki',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.48,
            box: [60, 680, 720, 940],
          ),
        ],
      ),
      // Scenario 2: Interior / Living Room / Pet
      _SceneData(
        description: 'Warm living room with a houseplant and soft ambient sunlight',
        objects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Plant',
            targetWord: '観葉植物',
            secondaryScript: 'かんようしょくぶつ',
            transliteration: 'kanyou shokubutsu',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N3',
            confidence: 0.94,
            box: [220, 310, 840, 760],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Window',
            targetWord: '窓',
            secondaryScript: 'まど',
            transliteration: 'mado',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.78,
            box: [50, 580, 780, 950],
          ),
          const DetectedObject(
            id: 'obj_03',
            labelEn: 'Chair',
            targetWord: '椅子',
            secondaryScript: 'いす',
            transliteration: 'isu',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.54,
            box: [410, 80, 920, 480],
          ),
        ],
      ),
      // Scenario 3: Technology / Workspace
      _SceneData(
        description: 'Modern workspace setup with laptop, notebook and mechanical keyboard',
        objects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Laptop',
            targetWord: 'パソコン',
            secondaryScript: 'ノートパソコン',
            transliteration: 'pasokon',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.95,
            box: [280, 220, 790, 810],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Clock',
            targetWord: '時計',
            secondaryScript: 'とけい',
            transliteration: 'tokei',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.84,
            box: [90, 750, 320, 930],
          ),
          const DetectedObject(
            id: 'obj_03',
            labelEn: 'Pen',
            targetWord: '万年筆',
            secondaryScript: 'まんねんひつ',
            transliteration: 'mannenhitsu',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N3',
            confidence: 0.50,
            box: [640, 110, 860, 310],
          ),
        ],
      ),
      // Scenario 4: Food & Dining
      _SceneData(
        description: 'Traditional dining plate with steaming tea and seasonal meal',
        objects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Green Tea',
            targetWord: 'お茶',
            secondaryScript: 'おちゃ',
            transliteration: 'ocha',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.94,
            box: [410, 560, 820, 880],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Plate',
            targetWord: '皿',
            secondaryScript: 'さら',
            transliteration: 'sara',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N4',
            confidence: 0.82,
            box: [310, 180, 870, 720],
          ),
          const DetectedObject(
            id: 'obj_03',
            labelEn: 'Chopsticks',
            targetWord: '箸',
            secondaryScript: 'はし',
            transliteration: 'hashi',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.45,
            box: [720, 220, 880, 820],
          ),
        ],
      ),
    ];

    final selected = scenarios[seed % scenarios.length];
    return AnalysisResult(
      sessionId: sessionId,
      languageCode: 'ja',
      primaryObjectId: selected.objects.first.id,
      sceneDescription: selected.description,
      detectedObjects: selected.objects,
    );
  }

  AnalysisResult _generateFilipinoResult(String sessionId, int seed) {
    final scenarios = [
      _SceneData(
        description: 'Study desk with open literature, warm coffee, and handwritten notes',
        objects: [
          DetectedObject(
            id: 'obj_01',
            labelEn: 'Book',
            targetWord: BaybayinEngine.transliterate('aklat'),
            secondaryScript: 'aklat',
            transliteration: '[ak-lat]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            confidence: 0.95,
            box: const [150, 180, 820, 750],
          ),
          DetectedObject(
            id: 'obj_02',
            labelEn: 'Coffee Mug',
            targetWord: BaybayinEngine.transliterate('tasa'),
            secondaryScript: 'tasa',
            transliteration: '[ta-sa]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            confidence: 0.88,
            box: const [480, 720, 850, 930],
          ),
          DetectedObject(
            id: 'obj_03',
            labelEn: 'Desk',
            targetWord: BaybayinEngine.transliterate('mesa'),
            secondaryScript: 'mesa',
            transliteration: '[me-sa]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A2',
            confidence: 0.50,
            box: const [50, 50, 950, 950],
          ),
        ],
      ),
      _SceneData(
        description: 'Vibrant outdoor pathway with tropical greenery and sunny afternoon breeze',
        objects: [
          DetectedObject(
            id: 'obj_01',
            labelEn: 'Tree',
            targetWord: BaybayinEngine.transliterate('puno'),
            secondaryScript: 'puno',
            transliteration: '[pu-no]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            confidence: 0.94,
            box: const [110, 210, 880, 780],
          ),
          DetectedObject(
            id: 'obj_02',
            labelEn: 'Road / Path',
            targetWord: BaybayinEngine.transliterate('daan'),
            secondaryScript: 'daan',
            transliteration: '[da-an]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            confidence: 0.82,
            box: const [480, 120, 950, 890],
          ),
          DetectedObject(
            id: 'obj_03',
            labelEn: 'Sunlight',
            targetWord: BaybayinEngine.transliterate('araw'),
            secondaryScript: 'araw',
            transliteration: '[a-raw]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            confidence: 0.45,
            box: const [50, 680, 350, 920],
          ),
        ],
      ),
      _SceneData(
        description: 'Dining area with tropical fruits and handmade native tableware',
        objects: [
          DetectedObject(
            id: 'obj_01',
            labelEn: 'Water',
            targetWord: BaybayinEngine.transliterate('tubig'),
            secondaryScript: 'tubig',
            transliteration: '[tu-big]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A1',
            confidence: 0.92,
            box: const [320, 480, 860, 820],
          ),
          DetectedObject(
            id: 'obj_02',
            labelEn: 'Plate',
            targetWord: BaybayinEngine.transliterate('pinggan'),
            secondaryScript: 'pinggan',
            transliteration: '[ping-gan]',
            partOfSpeech: 'Noun',
            difficultyLevel: 'A2',
            confidence: 0.86,
            box: const [290, 160, 820, 680],
          ),
        ],
      ),
    ];

    final selected = scenarios[seed % scenarios.length];
    return AnalysisResult(
      sessionId: sessionId,
      languageCode: 'fil',
      primaryObjectId: selected.objects.first.id,
      sceneDescription: selected.description,
      detectedObjects: selected.objects,
    );
  }

  AnalysisResult _generateSpanishResult(String sessionId, int seed, LanguageProfile language) {
    final scenarios = [
      _SceneData(
        description: 'Sunlit rustic table with hot coffee and reading materials',
        objects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Coffee Mug',
            targetWord: 'Taza',
            secondaryScript: 'la taza',
            transliteration: '[tah-sah]',
            partOfSpeech: 'Noun • f',
            difficultyLevel: 'A1',
            confidence: 0.95,
            box: [480, 720, 850, 930],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Book',
            targetWord: 'Libro',
            secondaryScript: 'el libro',
            transliteration: '[lee-bro]',
            partOfSpeech: 'Noun • m',
            difficultyLevel: 'A1',
            confidence: 0.88,
            box: [150, 180, 820, 750],
          ),
          const DetectedObject(
            id: 'obj_03',
            labelEn: 'Table',
            targetWord: 'Mesa',
            secondaryScript: 'la mesa',
            transliteration: '[meh-sah]',
            partOfSpeech: 'Noun • f',
            difficultyLevel: 'A1',
            confidence: 0.48,
            box: [50, 50, 950, 950],
          ),
        ],
      ),
      _SceneData(
        description: 'City square with classic architecture and quiet street corner',
        objects: [
          const DetectedObject(
            id: 'obj_01',
            labelEn: 'Bicycle',
            targetWord: 'Bicicleta',
            secondaryScript: 'la bicicleta',
            transliteration: '[bee-see-kleh-tah]',
            partOfSpeech: 'Noun • f',
            difficultyLevel: 'A1',
            confidence: 0.94,
            box: [320, 210, 880, 790],
          ),
          const DetectedObject(
            id: 'obj_02',
            labelEn: 'Street',
            targetWord: 'Calle',
            secondaryScript: 'la calle',
            transliteration: '[kah-yeh]',
            partOfSpeech: 'Noun • f',
            difficultyLevel: 'A1',
            confidence: 0.52,
            box: [100, 50, 950, 950],
          ),
        ],
      ),
    ];

    final selected = scenarios[seed % scenarios.length];
    return AnalysisResult(
      sessionId: sessionId,
      languageCode: language.code,
      primaryObjectId: selected.objects.first.id,
      sceneDescription: selected.description,
      detectedObjects: selected.objects,
    );
  }
}

class _SceneData {
  final String description;
  final List<DetectedObject> objects;

  const _SceneData({
    required this.description,
    required this.objects,
  });
}
