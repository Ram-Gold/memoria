import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/baybayin_engine.dart';
import 'package:memoria/core/services/app_tts_service.dart';
import 'package:memoria/data/services/local_object_lexicon.dart';

void main() {
  group('AppTtsService text sanitization and phonetic extraction', () {
    test('Filipino pronunciation extracts pure Latin Tagalog and never Baybayin glyphs', () {
      // 1. Slash removal and english word stripping
      final text1 = AppTtsService.extractPronunciationText(
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('tasa'),
        secondaryScript: 'tasa / mug',
        transliteration: '[ta-sa]',
      );
      expect(text1, equals('tasa'));
      expect(BaybayinEngine.hasBaybayinGlyphs(text1), isFalse);

      // 2. Transliteration bracket stripping when secondary script is absent
      final text2 = AppTtsService.extractPronunciationText(
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('aklat'),
        secondaryScript: null,
        transliteration: '[ak-lat]',
      );
      expect(text2, equals('ak lat'));
      expect(BaybayinEngine.hasBaybayinGlyphs(text2), isFalse);

      // 3. Pure single-word secondary script
      final text3 = AppTtsService.extractPronunciationText(
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('halaman'),
        secondaryScript: 'halaman',
        transliteration: '[ha-la-man]',
      );
      expect(text3, equals('halaman'));
      expect(BaybayinEngine.hasBaybayinGlyphs(text3), isFalse);
    });

    test('Japanese pronunciation prioritizes pure Kana reading for pitch accent', () {
      final text = AppTtsService.extractPronunciationText(
        languageCode: 'ja',
        targetWord: 'マグカップ',
        secondaryScript: 'まぐかっぷ',
        transliteration: 'magukappu',
      );
      // Kana reading guarantees zero Kanji pronunciation misreadings
      expect(text, equals('まぐかっぷ'));

      final textKanji = AppTtsService.extractPronunciationText(
        languageCode: 'ja',
        targetWord: '珈琲碗',
        secondaryScript: 'コーヒーカップ',
        transliteration: 'koohii kappu',
      );
      expect(textKanji, equals('コーヒーカップ'));
    });

    test('Spanish pronunciation strips slashes to primary vocabulary', () {
      final text = AppTtsService.extractPronunciationText(
        languageCode: 'es',
        targetWord: 'Taza',
        secondaryScript: 'la taza / el tazón',
        transliteration: '[tah-sah]',
      );
      expect(text, equals('la taza'));
    });
  });

  group('LocalObjectLexicon synonym normalization and saliency weighting', () {
    test('Normalizes detector synonyms to canonical keys', () {
      expect(LocalObjectLexicon.normalizeClassName('Coffee mug'), equals('mug'));
      expect(LocalObjectLexicon.normalizeClassName('drinkware'), equals('cup'));
      expect(LocalObjectLexicon.normalizeClassName('houseplant'), equals('potted plant'));
      expect(LocalObjectLexicon.normalizeClassName('smartphone'), equals('cell phone'));
      expect(LocalObjectLexicon.normalizeClassName('dining table'), equals('dining table'));
    });

    test('Foreground focal objects have significantly higher saliency weight than background scenery', () {
      final mugWeight = LocalObjectLexicon.getSaliencyWeight('mug');
      final plantWeight = LocalObjectLexicon.getSaliencyWeight('potted plant');
      final tableWeight = LocalObjectLexicon.getSaliencyWeight('dining table');

      expect(mugWeight, greaterThan(plantWeight));
      expect(plantWeight, greaterThan(tableWeight));

      // Verifies the user scenario: Mug confidence 0.75 vs Plant 0.80 vs Table 0.85
      final mugScore = 0.75 * mugWeight;     // 0.75 * 1.6 = 1.20
      final plantScore = 0.80 * plantWeight; // 0.80 * 1.1 = 0.88
      final tableScore = 0.85 * tableWeight; // 0.85 * 0.7 = 0.595

      expect(mugScore, greaterThan(plantScore));
      expect(mugScore, greaterThan(tableScore));
    });

    test('Japanese and Filipino lookups provide complete pedagogical entries', () {
      final mugJa = LocalObjectLexicon.lookup(className: 'mug', langCode: 'ja');
      expect(mugJa, isNotNull);
      expect(mugJa!.targetWord, equals('マグカップ'));
      expect(mugJa.secondaryScript, equals('まぐかっぷ'));
      expect(mugJa.transliteration, equals('magukappu'));

      final mugFil = LocalObjectLexicon.lookup(className: 'mug', langCode: 'fil');
      expect(mugFil, isNotNull);
      expect(BaybayinEngine.hasBaybayinGlyphs(mugFil!.targetWord), isTrue);
      expect(mugFil.secondaryScript, equals('tasa'));
      expect(mugFil.transliteration, equals('[ta-sa]'));
    });

    test('Synthesizes valid entries for unknown objects without leaving raw English', () {
      final unknownFil = LocalObjectLexicon.synthesizeEntry(label: 'telescope', langCode: 'fil');
      expect(BaybayinEngine.hasBaybayinGlyphs(unknownFil.targetWord), isTrue);
      expect(unknownFil.secondaryScript, equals('telescope'));
    });
  });
}
