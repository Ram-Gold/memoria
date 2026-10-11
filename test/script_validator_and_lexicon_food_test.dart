import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/script_validator.dart';
import 'package:memoria/core/rag/rag_service.dart';
import 'package:memoria/data/repositories/polaroid_repository.dart';
import 'package:memoria/data/services/local_object_lexicon.dart';
import 'package:memoria/domain/models/analysis_result.dart';
import 'package:memoria/domain/models/detected_object.dart';
import 'package:memoria/domain/models/polaroid.dart';

void main() {
  group('ScriptValidator Orthographic Gatekeeper Tests', () {
    test('Rejects pure ASCII English for Japanese', () {
      expect(ScriptValidator.isValidTargetWord('Food', 'ja'), isFalse);
      expect(ScriptValidator.isValidTargetWord('Chicken', 'ja'), isFalse);
      expect(ScriptValidator.isValidTargetWord('Ice cream', 'ja'), isFalse);
      expect(ScriptValidator.isValidTargetWord('Coffee cup', 'ja'), isFalse);
    });

    test('Accepts authentic Japanese Kana and Kanji', () {
      expect(ScriptValidator.isValidTargetWord('食べ物', 'ja'), isTrue);
      expect(ScriptValidator.isValidTargetWord('たべもの', 'ja'), isTrue);
      expect(ScriptValidator.isValidTargetWord('鶏肉', 'ja'), isTrue);
      expect(ScriptValidator.isValidTargetWord('アイスクリーム', 'ja'), isTrue);
      expect(ScriptValidator.isValidTargetWord('猫', 'ja'), isTrue);
      expect(ScriptValidator.isValidTargetWord('本', 'ja'), isTrue);
    });

    test('Rejects pure ASCII English for Mandarin Chinese', () {
      expect(ScriptValidator.isValidTargetWord('Food', 'zh'), isFalse);
      expect(ScriptValidator.isValidTargetWord('Chicken', 'zh'), isFalse);
      expect(ScriptValidator.isValidTargetWord('Ice cream', 'zh'), isFalse);
    });

    test('Accepts authentic Simplified Hanzi for Mandarin Chinese', () {
      expect(ScriptValidator.isValidTargetWord('食物', 'zh'), isTrue);
      expect(ScriptValidator.isValidTargetWord('鸡肉', 'zh'), isTrue);
      expect(ScriptValidator.isValidTargetWord('冰淇淋', 'zh'), isTrue);
      expect(ScriptValidator.isValidTargetWord('猫', 'zh'), isTrue);
      expect(ScriptValidator.isValidTargetWord('书', 'zh'), isTrue);
    });

    test('Detects leaked English accurately', () {
      expect(ScriptValidator.isLeakedEnglish('Food', 'Food', 'ja'), isTrue);
      expect(ScriptValidator.isLeakedEnglish('Chicken', 'Chicken', 'ja'), isTrue);
      expect(ScriptValidator.isLeakedEnglish('Food', 'Food', 'zh'), isTrue);
      expect(ScriptValidator.isLeakedEnglish('Food', 'Food', 'fil'), isTrue);

      expect(ScriptValidator.isLeakedEnglish('食べ物', 'Food', 'ja'), isFalse);
      expect(ScriptValidator.isLeakedEnglish('食物', 'Food', 'zh'), isFalse);
      expect(ScriptValidator.isLeakedEnglish('pagkain', 'Food', 'fil'), isFalse);
    });

    test('Sanitizes and repairs leaked English object to authentic native script', () {
      const leakedObj = DetectedObject(
        id: 'obj_01',
        labelEn: 'Food',
        targetWord: 'Food', // Raw English leak
        secondaryScript: 'Food',
        transliteration: 'food',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        confidence: 0.95,
        box: [100, 100, 800, 800],
      );

      final repairedJa = ScriptValidator.sanitizeObject(leakedObj, 'ja');
      expect(repairedJa.targetWord, '食べ物');
      expect(repairedJa.secondaryScript, 'たべもの');
      expect(repairedJa.transliteration, 'tabemono');
      expect(ScriptValidator.isValidTargetWord(repairedJa.targetWord, 'ja'), isTrue);

      final repairedZh = ScriptValidator.sanitizeObject(leakedObj, 'zh');
      expect(repairedZh.targetWord, '食物');
      expect(repairedZh.transliteration, 'shíwù');
      expect(ScriptValidator.isValidTargetWord(repairedZh.targetWord, 'zh'), isTrue);
    });
  });

  group('LocalObjectLexicon Food & Dining Expansion Tests', () {
    test('Looks up food, chicken, and ice cream in Japanese', () {
      final foodJa = LocalObjectLexicon.lookup(className: 'food', langCode: 'ja');
      expect(foodJa, isNotNull);
      expect(foodJa!.targetWord, '食べ物');
      expect(foodJa.transliteration, 'tabemono');

      final chickenJa = LocalObjectLexicon.lookup(className: 'chicken', langCode: 'ja');
      expect(chickenJa, isNotNull);
      expect(chickenJa!.targetWord, '鶏肉');
      expect(chickenJa.transliteration, 'toriniku');

      final iceCreamJa = LocalObjectLexicon.lookup(className: 'ice cream', langCode: 'ja');
      expect(iceCreamJa, isNotNull);
      expect(iceCreamJa!.targetWord, 'アイスクリーム');
      expect(iceCreamJa.transliteration, 'aisukuriimu');
    });

    test('Normalizes ML Kit synonyms for food and frozen desserts', () {
      final fastFoodJa = LocalObjectLexicon.lookup(className: 'fast food', langCode: 'ja');
      expect(fastFoodJa, isNotNull);
      expect(fastFoodJa!.targetWord, '食べ物');

      final frozenDessertJa = LocalObjectLexicon.lookup(className: 'frozen dessert', langCode: 'ja');
      expect(frozenDessertJa, isNotNull);
      expect(frozenDessertJa!.targetWord, 'アイスクリーム');

      final poultryJa = LocalObjectLexicon.lookup(className: 'poultry', langCode: 'ja');
      expect(poultryJa, isNotNull);
      expect(poultryJa!.targetWord, '鶏肉');
    });

    test('Looks up food, chicken, and ice cream in Filipino with Baybayin', () {
      final foodFil = LocalObjectLexicon.lookup(className: 'food', langCode: 'fil');
      expect(foodFil, isNotNull);
      expect(foodFil!.secondaryScript, 'pagkain');
      expect(foodFil.transliteration, '[pag-ka-in]');

      final chickenFil = LocalObjectLexicon.lookup(className: 'chicken', langCode: 'fil');
      expect(chickenFil, isNotNull);
      expect(chickenFil!.secondaryScript, 'manok');
      expect(chickenFil.transliteration, '[ma-nok]');

      final iceCreamFil = LocalObjectLexicon.lookup(className: 'ice cream', langCode: 'fil');
      expect(iceCreamFil, isNotNull);
      expect(iceCreamFil!.secondaryScript, 'sorbetes');
      expect(iceCreamFil.transliteration, '[sor-be-tes]');
    });

    test('Looks up food, chicken, and ice cream in Mandarin Chinese', () {
      final foodZh = LocalObjectLexicon.lookup(className: 'food', langCode: 'zh');
      expect(foodZh, isNotNull);
      expect(foodZh!.targetWord, '食物');
      expect(foodZh.transliteration, 'shíwù');

      final chickenZh = LocalObjectLexicon.lookup(className: 'chicken', langCode: 'zh');
      expect(chickenZh, isNotNull);
      expect(chickenZh!.targetWord, '鸡肉');
      expect(chickenZh.transliteration, 'jīròu');

      final iceCreamZh = LocalObjectLexicon.lookup(className: 'ice cream', langCode: 'zh');
      expect(iceCreamZh, isNotNull);
      expect(iceCreamZh!.targetWord, '冰淇淋');
      expect(iceCreamZh.transliteration, 'bīngqílín');
    });

    test('Looks up food, chicken, and ice cream in Spanish', () {
      final foodEs = LocalObjectLexicon.lookup(className: 'food', langCode: 'es');
      expect(foodEs, isNotNull);
      expect(foodEs!.targetWord, 'Comida');

      final chickenEs = LocalObjectLexicon.lookup(className: 'chicken', langCode: 'es');
      expect(chickenEs, isNotNull);
      expect(chickenEs!.targetWord, 'Pollo');

      final iceCreamEs = LocalObjectLexicon.lookup(className: 'ice cream', langCode: 'es');
      expect(iceCreamEs, isNotNull);
      expect(iceCreamEs!.targetWord, 'Helado');
    });

    test('synthesizeEntry NEVER returns raw English for unmapped labels', () {
      // Test unmapped food-related item
      final entryJaFood = LocalObjectLexicon.synthesizeEntry(
        label: 'mysterious culinary foodstuff',
        langCode: 'ja',
      );
      expect(entryJaFood.targetWord, '食べ物');
      expect(entryJaFood.secondaryScript, 'たべもの');
      expect(entryJaFood.transliteration, 'tabemono');
      expect(ScriptValidator.isValidTargetWord(entryJaFood.targetWord, 'ja'), isTrue);

      // Test completely unknown item
      final entryJaItem = LocalObjectLexicon.synthesizeEntry(
        label: 'mysterious strange item',
        langCode: 'ja',
      );
      expect(entryJaItem.targetWord, '物');
      expect(entryJaItem.secondaryScript, 'もの');
      expect(entryJaItem.transliteration, 'mono');
      expect(ScriptValidator.isValidTargetWord(entryJaItem.targetWord, 'ja'), isTrue);

      // Chinese unknown food item
      final entryZhFood = LocalObjectLexicon.synthesizeEntry(
        label: 'exotic culinary food',
        langCode: 'zh',
      );
      expect(entryZhFood.targetWord, '食物');
      expect(entryZhFood.transliteration, 'shíwù');
      expect(ScriptValidator.isValidTargetWord(entryZhFood.targetWord, 'zh'), isTrue);
    });
  });

  group('RagService Sanitization Integration Tests', () {
    test('augment automatically repairs leaked English in raw AnalysisResult', () async {
      final fakeRepo = _TestFakeRepo();
      final ragService = RagService(repository: fakeRepo);

      final rawResult = AnalysisResult(
        sessionId: 'test_session',
        languageCode: 'ja',
        primaryObjectId: 'obj_01',
        sceneDescription: 'Test food scene',
        detectedObjects: const [
          DetectedObject(
            id: 'obj_01',
            labelEn: 'Food',
            targetWord: 'Food', // Leaked English!
            secondaryScript: 'Food',
            transliteration: 'food',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.95,
            box: [100, 100, 800, 800],
          ),
          DetectedObject(
            id: 'obj_02',
            labelEn: 'Chicken',
            targetWord: 'Chicken', // Leaked English!
            secondaryScript: 'Chicken',
            transliteration: 'chicken',
            partOfSpeech: 'Noun',
            difficultyLevel: 'N5',
            confidence: 0.90,
            box: [200, 200, 700, 700],
          ),
        ],
      );

      final augmented = await ragService.augment(
        rawResult: rawResult,
        languageCode: 'ja',
      );

      final primary = augmented.primaryObject!;
      expect(primary.targetWord, '食べ物');
      expect(primary.secondaryScript, 'たべもの');
      expect(primary.transliteration, 'tabemono');
      expect(ScriptValidator.isValidTargetWord(primary.targetWord, 'ja'), isTrue);

      final second = augmented.detectedObjects[1];
      expect(second.targetWord, '鶏肉');
      expect(second.secondaryScript, 'とりにく');
      expect(second.transliteration, 'toriniku');
      expect(ScriptValidator.isValidTargetWord(second.targetWord, 'ja'), isTrue);
    });
  });
}

class _TestFakeRepo extends PolaroidRepository {
  @override
  Future<List<Polaroid>> findPolaroidsByObjectLabel(String labelEn, {String? languageCode}) async {
    return [];
  }
}
