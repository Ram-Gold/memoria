import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/data/services/local_object_lexicon.dart';
import 'package:memoria/domain/models/detected_object.dart';
import 'package:memoria/domain/models/polaroid.dart';

void main() {
  group('LocalObjectLexicon Reverse Lookup & Bidirectional Grounding', () {
    test('resolves Japanese "neko", "猫", and "ねこ" to English "Cat"', () {
      final matchRomaji = LocalObjectLexicon.reverseLookup(
        transliteration: 'neko',
        langCode: 'ja',
      );
      expect(matchRomaji, isNotNull);
      expect(matchRomaji!.labelEn, equals('Cat'));
      expect(matchRomaji.targetWord, equals('猫'));

      final matchKanji = LocalObjectLexicon.reverseLookup(
        targetWord: '猫',
        langCode: 'ja',
      );
      expect(matchKanji, isNotNull);
      expect(matchKanji!.labelEn, equals('Cat'));

      final matchHiragana = LocalObjectLexicon.reverseLookup(
        secondaryScript: 'ねこ',
        langCode: 'ja',
      );
      expect(matchHiragana, isNotNull);
      expect(matchHiragana!.labelEn, equals('Cat'));
    });

    test('bidirectional lookup() automatically delegates to reverseLookup for native words and romaji', () {
      final lookupKanji = LocalObjectLexicon.lookup(
        className: '猫',
        langCode: 'ja',
      );
      expect(lookupKanji, isNotNull);
      expect(lookupKanji!.labelEn, equals('Cat'));

      final lookupRomaji = LocalObjectLexicon.lookup(
        className: 'neko',
        langCode: 'ja',
      );
      expect(lookupRomaji, isNotNull);
      expect(lookupRomaji!.labelEn, equals('Cat'));
    });

    test('resolves other multilingual vocabulary in reverse', () {
      // Filipino
      final pusa = LocalObjectLexicon.reverseLookup(
        targetWord: 'pusa',
        langCode: 'fil',
      );
      expect(pusa, isNotNull);
      expect(pusa!.labelEn, equals('Cat'));

      // Spanish
      final gato = LocalObjectLexicon.reverseLookup(
        targetWord: 'el gato',
        langCode: 'es',
      );
      expect(gato, isNotNull);
      expect(gato!.labelEn, equals('Cat'));

      // Japanese coffee cup
      final coffee = LocalObjectLexicon.reverseLookup(
        targetWord: '珈琲碗',
        langCode: 'ja',
      );
      expect(coffee, isNotNull);
      expect(coffee!.labelEn, equals('Coffee Mug'));
    });
  });

  group('DetectedObject.fromJson Defensive LLM Parsing', () {
    test('recovers labelEn via reverseLookup when LLM provides generic or empty label', () {
      final objGeneric = DetectedObject.fromJson({
        'id': 'obj_01',
        'label_en': 'object',
        'target_word': '猫',
        'transliteration': 'neko',
        'secondary_script': 'ねこ',
      });
      expect(objGeneric.labelEn, equals('Cat'));

      final objEmpty = DetectedObject.fromJson({
        'id': 'obj_02',
        'label_en': '',
        'target_word': '猫',
        'transliteration': 'neko',
      });
      expect(objEmpty.labelEn, equals('Cat'));
    });

    test('parses common LLM key variations (english_meaning, meaning, english)', () {
      final objMeaning = DetectedObject.fromJson({
        'id': 'obj_01',
        'english_meaning': 'Cat',
        'target_word': '猫',
        'romaji': 'neko',
      });
      expect(objMeaning.labelEn, equals('Cat'));
      expect(objMeaning.transliteration, equals('neko'));

      final objEnglish = DetectedObject.fromJson({
        'id': 'obj_02',
        'english': 'Cat',
        'target_word': '猫',
      });
      expect(objEnglish.labelEn, equals('Cat'));
    });
  });

  group('Polaroid Model resolvedEnglishLabel Invariant', () {
    test('resolves "Cat" from selectedWord "猫" and transliteration "neko" even with empty detectedObjects', () {
      final polaroid = Polaroid(
        id: 'pol_1',
        imagePath: '/dummy.jpg',
        outputImagePath: '/dummy.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj_01',
        selectedWord: '猫',
        transliteration: 'neko',
        secondaryScript: 'ねこ',
        createdAt: DateTime.now(),
        detectedObjects: const [], // Empty list (e.g. filtered out by threshold or legacy storage)
      );

      expect(polaroid.resolvedEnglishLabel, equals('Cat'));
      expect(polaroid.resolvedEnglishLabel, isNot(contains('Language learning artifact')));
    });

    test('prioritizes direct labelEn on Polaroid if present', () {
      final polaroid = Polaroid(
        id: 'pol_2',
        imagePath: '/dummy.jpg',
        outputImagePath: '/dummy.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj_01',
        selectedWord: '猫',
        labelEn: 'Feline Friend',
        transliteration: 'neko',
        createdAt: DateTime.now(),
      );

      expect(polaroid.resolvedEnglishLabel, equals('Feline Friend'));
    });

    test('never returns "Language learning artifact" even for unknown words', () {
      final polaroid = Polaroid(
        id: 'pol_3',
        imagePath: '/dummy.jpg',
        outputImagePath: '/dummy.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj_01',
        selectedWord: '謎の物体',
        transliteration: 'nazo no buttai',
        createdAt: DateTime.now(),
        detectedObjects: const [],
      );

      expect(polaroid.resolvedEnglishLabel, isNot(contains('Language learning artifact')));
      expect(polaroid.resolvedEnglishLabel, equals('Nazo no buttai'));
    });
  });
}
