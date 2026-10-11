import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/baybayin_engine.dart';
import 'package:memoria/core/languages/chin_format_helper.dart';
import 'package:memoria/domain/models/polaroid.dart';

void main() {
  group('Polaroid Full Customization Tests', () {
    test('Polaroid model copyWith updates all user-customized fields', () {
      final original = Polaroid(
        id: 'test_pol_1',
        imagePath: '/tmp/test.jpg',
        outputImagePath: '/tmp/test_out.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj_1',
        selectedWord: '犬',
        labelEn: 'Dog',
        transliteration: 'inu',
        secondaryScript: 'いぬ',
        createdAt: DateTime.now(),
      );

      final customized = original.copyWith(
        selectedWord: '子犬',
        labelEn: 'Puppy',
        transliteration: 'koinu',
        secondaryScript: 'こいぬ',
      );

      expect(customized.id, equals('test_pol_1'));
      expect(customized.selectedWord, equals('子犬'));
      expect(customized.labelEn, equals('Puppy'));
      expect(customized.transliteration, equals('koinu'));
      expect(customized.secondaryScript, equals('こいぬ'));
      expect(customized.imagePath, equals('/tmp/test.jpg'));
    });

    test('ChinFormatHelper formats customized values accurately on chin lines', () {
      final chinJapanese = ChinFormatHelper.format(
        targetWord: '子犬',
        secondaryScript: 'こいぬ',
        transliteration: 'koinu',
        labelEn: 'Puppy',
        languageCode: 'ja',
      );

      expect(chinJapanese.line1, equals('子犬 (Puppy)'));
      expect(chinJapanese.line2, equals('(koinu)'));

      final chinTagalog = ChinFormatHelper.format(
        targetWord: 'ᜉᜓᜐ',
        secondaryScript: 'pusa',
        labelEn: 'Cat',
        languageCode: 'fil',
      );

      expect(chinTagalog.line1, equals('ᜉᜓᜐ (Cat)'));
      expect(chinTagalog.line2, equals('(pusa · [pu-sa])'));
    });

    test('BaybayinEngine auto-transcribes manual customizations accurately', () {
      const manualWord = 'pusa';
      final baybayin = BaybayinEngine.transliterate(manualWord);
      final pronunciation = BaybayinEngine.formatPronunciation(manualWord);

      expect(baybayin, equals('\u1709\u1713\u170F'));
      expect(pronunciation, equals('[pu-sa]'));
      expect(BaybayinEngine.hasBaybayinGlyphs(baybayin), isTrue);
    });
  });
}
