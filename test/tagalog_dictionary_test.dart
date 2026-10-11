import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/baybayin_engine.dart';
import 'package:memoria/core/services/tagalog_dictionary_service.dart';

void main() {
  group('TagalogDictionaryService Tests', () {
    final service = TagalogDictionaryService.instance;

    test('looks up verified Tagalog words by English label', () {
      final dogEntry = service.lookupByEnglish('dog');
      expect(dogEntry, isNotNull);
      expect(dogEntry!.word, 'aso');
      expect(dogEntry.labelEn, 'Dog');
      // Baybayin for aso: a (ᜀ) + sa with kudlitU (ᜐᜓ)
      expect(dogEntry.baybayin, '\u1700\u170F\u1713');
      expect(dogEntry.pronunciation, '[a-so]');

      final cupEntry = service.lookupByEnglish('cup');
      expect(cupEntry, isNotNull);
      expect(cupEntry!.word, 'tasa');
      expect(cupEntry.baybayin, '\u1706\u170F'); // ta (ᜆ) + sa (ᜐ)
    });

    test('handles everyday COCO objects (spoon, table, shoes, chair, book)', () {
      expect(service.lookupByEnglish('spoon')?.word, 'kutsara');
      expect(service.lookupByEnglish('chair')?.word, 'silya');
      expect(service.lookupByEnglish('table')?.word, 'mesa');
      expect(service.lookupByEnglish('shoes')?.word, 'sapatos');
      expect(service.lookupByEnglish('book')?.word, 'aklat');
      expect(service.lookupByEnglish('window')?.word, 'bintana');
    });

    test('retrieves regional Pangasinan cognates', () {
      final house = service.lookupByTagalog('bahay');
      expect(house, isNotNull);
      expect(house!.pangasinanCognate, 'abong');

      final water = service.lookupByTagalog('tubig');
      expect(water, isNotNull);
      expect(water!.pangasinanCognate, 'danum');

      expect(PhilippineRegionalLexicon.getPangasinanEquivalent('aso'), 'aso');
      expect(PhilippineRegionalLexicon.getPangasinanEquivalent('kain'), 'mangan');
    });

    test('resolveOrSynthesize guarantees valid Tagalog and Baybayin without raw English', () {
      // Known word
      final known = service.resolveOrSynthesize('laptop');
      expect(known.word, 'kompyuter');
      expect(BaybayinEngine.hasBaybayinGlyphs(known.baybayin), isTrue);

      // Unknown English term gets phonetically adapted
      final synthesized = service.resolveOrSynthesize('chocolate');
      expect(synthesized.word, 'tsokolate');
      expect(BaybayinEngine.hasBaybayinGlyphs(synthesized.baybayin), isTrue);
    });

    test('JSON serialization round-trip', () {
      final entry = service.lookupByEnglish('coffee')!;
      final json = entry.toJson();
      final restored = TagalogWordEntry.fromJson(json);

      expect(restored.word, entry.word);
      expect(restored.baybayin, entry.baybayin);
      expect(restored.pronunciation, entry.pronunciation);
    });
  });
}
