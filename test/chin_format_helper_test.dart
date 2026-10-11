import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/chin_format_helper.dart';
import 'package:memoria/domain/models/detected_object.dart';

void main() {
  group('ChinFormatHelper Tests', () {
    test('Japanese formatting creates "Kanji/Kana (Meaning)" and "(romaji)"', () {
      final chin = ChinFormatHelper.format(
        targetWord: '猫',
        secondaryScript: 'ねこ',
        transliteration: 'neko',
        labelEn: 'cat',
        languageCode: 'ja',
      );

      expect(chin.line1, equals('猫 (Cat)'));
      expect(chin.line2, equals('(neko)'));
    });

    test('Japanese strips redundant outer parentheses from transliteration', () {
      final chin = ChinFormatHelper.format(
        targetWord: '本',
        transliteration: '(hon)',
        labelEn: 'book',
        languageCode: 'ja',
      );

      expect(chin.line1, equals('本 (Book)'));
      expect(chin.line2, equals('(hon)'));
    });

    test('Filipino / Baybayin formatting creates "Baybayin (Meaning)" and "(tagalog · [phonetic])"', () {
      final chin = ChinFormatHelper.format(
        targetWord: 'ᜀᜃ᜔ᜎᜆ᜔',
        secondaryScript: 'aklat',
        transliteration: '[ak-lat]',
        labelEn: 'book',
        languageCode: 'fil',
      );

      expect(chin.line1, equals('ᜀᜃ᜔ᜎᜆ᜔ (Book)'));
      expect(chin.line2, equals('(aklat · [ak-lat])'));
    });

    test('Filipino auto-formats phonetic guide if transliteration missing', () {
      final chin = ChinFormatHelper.format(
        targetWord: 'ᜉᜓᜐ',
        secondaryScript: 'pusa',
        labelEn: 'cat',
        languageCode: 'fil',
      );

      expect(chin.line1, equals('ᜉᜓᜐ (Cat)'));
      expect(chin.line2, equals('(pusa · [pu-sa])'));
    });

    test('Mandarin Chinese formatting creates "Hanzi (Meaning)" and "(pinyin)"', () {
      final chin = ChinFormatHelper.format(
        targetWord: '书',
        secondaryScript: '书',
        transliteration: 'shū',
        labelEn: 'book',
        languageCode: 'zh',
      );

      expect(chin.line1, equals('书 (Book)'));
      expect(chin.line2, equals('(shū)'));
    });

    test('Omits empty or placeholder English labels like "item" or "object"', () {
      final chin = ChinFormatHelper.format(
        targetWord: '猫',
        transliteration: 'neko',
        labelEn: 'item',
        languageCode: 'ja',
      );

      expect(chin.line1, equals('猫'));
      expect(chin.line2, equals('(neko)'));
    });

    test('formatFromObject handles DetectedObject correctly', () {
      const obj = DetectedObject(
        id: 'obj_01',
        labelEn: 'coffee cup',
        targetWord: 'コップ',
        transliteration: 'koppu',
        box: [100, 100, 500, 500],
      );

      final chin = ChinFormatHelper.formatFromObject(obj, 'ja');
      expect(chin.line1, equals('コップ (Coffee Cup)'));
      expect(chin.line2, equals('(koppu)'));
    });
  });
}
