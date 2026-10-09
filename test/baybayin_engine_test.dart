import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/baybayin_engine.dart';

void main() {
  group('BaybayinEngine Tests', () {
    test('transliterates aklat correctly with virama', () {
      final result = BaybayinEngine.transliterate('aklat');
      // a (ᜀ) + ka with virama (ᜃ᜔) + la (ᜎ) + ta with virama (ᜆ᜔)
      expect(result, '\u1700\u1703\u1714\u170D\u1706\u1714');
      expect(BaybayinEngine.hasBaybayinGlyphs(result), isTrue);
    });

    test('transliterates pusa correctly with kudlitU', () {
      final result = BaybayinEngine.transliterate('pusa');
      // pa with kudlitU (ᜉᜓ) + sa (ᜐ)
      expect(result, '\u1709\u1713\u170F');
      expect(BaybayinEngine.hasBaybayinGlyphs(result), isTrue);
    });

    test('hasBaybayinGlyphs detects Tagalog Unicode range', () {
      expect(BaybayinEngine.hasBaybayinGlyphs('ᜀᜃ᜔ᜎᜆ᜔'), isTrue);
      expect(BaybayinEngine.hasBaybayinGlyphs('book'), isFalse);
      expect(BaybayinEngine.hasBaybayinGlyphs('ほん'), isFalse);
    });
  });
}
