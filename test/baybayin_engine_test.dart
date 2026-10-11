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

    test('transliterates special particle mga correctly as manga', () {
      final result = BaybayinEngine.transliterate('mga');
      // ma (ᜋ) + nga (ᜅ)
      expect(result, '\u170B\u1705');
    });

    test('transliterates special particle ng correctly as nang', () {
      final result = BaybayinEngine.transliterate('ng');
      // na (ᜈ) + nga with virama (ᜅ᜔)
      expect(result, '\u1708\u1705\u1714');
    });

    test('supports traditional pre-colonial kaltas mode (coda dropping)', () {
      final result = BaybayinEngine.transliterate('aklat', mode: BaybayinMode.traditional);
      // a (ᜀ) + la (ᜎ) [k and t codas dropped]
      expect(result, '\u1700\u170D');
    });

    test('normalizes loanwords with Spanish / foreign orthography', () {
      expect(BaybayinEngine.normalizeTagalogPhonetics('chocolate'), 'tsokolate');
      expect(BaybayinEngine.normalizeTagalogPhonetics('fiesta'), 'piesta');
      expect(BaybayinEngine.normalizeTagalogPhonetics('centro'), 'sentro');
      expect(BaybayinEngine.normalizeTagalogPhonetics('vaso'), 'baso');
    });

    test('syllabicates Tagalog words accurately', () {
      expect(BaybayinEngine.syllabicate('aklat'), ['ak', 'lat']);
      expect(BaybayinEngine.syllabicate('pusa'), ['pu', 'sa']);
      expect(BaybayinEngine.syllabicate('mesa'), ['me', 'sa']);
      expect(BaybayinEngine.formatPronunciation('bulaklak'), '[bu-lak-lak]');
    });
  });
}
