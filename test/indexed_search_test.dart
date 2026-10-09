import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/domain/models/detected_object.dart';
import 'package:memoria/domain/models/polaroid.dart';

void main() {
  group('Indexed Search Logic Tests', () {
    final List<Polaroid> samplePolaroids = [
      Polaroid(
        id: 'p1',
        imagePath: '/tmp/p1.jpg',
        outputImagePath: '/tmp/p1.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj-1',
        selectedWord: '珈琲',
        secondaryScript: 'こーひー',
        transliteration: 'koohii',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        detectedObjects: const [
          DetectedObject(
            id: 'obj-1',
            labelEn: 'Coffee Mug',
            targetWord: '珈琲',
            secondaryScript: 'こーひー',
            box: [0, 0, 500, 500],
          ),
        ],
      ),
      Polaroid(
        id: 'p2',
        imagePath: '/tmp/p2.jpg',
        outputImagePath: '/tmp/p2.jpg',
        languageCode: 'fil',
        selectedObjectId: 'obj-2',
        selectedWord: 'ᜀᜃ᜔ᜎᜆ᜔',
        secondaryScript: 'aklat',
        transliteration: '[ak-lat]',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        detectedObjects: const [
          DetectedObject(
            id: 'obj-2',
            labelEn: 'Book',
            targetWord: 'ᜀᜃ᜔ᜎᜆ᜔',
            secondaryScript: 'aklat',
            box: [0, 0, 500, 500],
          ),
        ],
      ),
      Polaroid(
        id: 'p3',
        imagePath: '/tmp/p3.jpg',
        outputImagePath: '/tmp/p3.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj-3',
        selectedWord: '猫',
        secondaryScript: 'ねこ',
        transliteration: 'neko',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        detectedObjects: const [
          DetectedObject(
            id: 'obj-3',
            labelEn: 'Cat',
            targetWord: '猫',
            secondaryScript: 'ねこ',
            box: [0, 0, 500, 500],
          ),
        ],
      ),
    ];


    List<Polaroid> filterMemories(String query, {String? languageCode}) {
      final clean = query.trim().toLowerCase();
      if (clean.isEmpty) return samplePolaroids;

      return samplePolaroids.where((p) {
        if (languageCode != null && p.languageCode != languageCode) return false;
        final matchWord = p.selectedWord.toLowerCase().contains(clean);
        final matchSec = p.secondaryScript?.toLowerCase().contains(clean) ?? false;
        final matchTrans = p.transliteration?.toLowerCase().contains(clean) ?? false;
        final matchObj = p.detectedObjects.any((o) =>
            o.labelEn.toLowerCase().contains(clean) ||
            o.targetWord.toLowerCase().contains(clean));
        return matchWord || matchSec || matchTrans || matchObj;
      }).toList();
    }

    test('searches by Romaji / transliteration', () {
      final results = filterMemories('koohii');
      expect(results.length, 1);
      expect(results.first.id, 'p1');
    });

    test('searches by English object label', () {
      final results = filterMemories('book');
      expect(results.length, 1);
      expect(results.first.id, 'p2');
    });

    test('searches by secondary script / phonetic', () {
      final results = filterMemories('ねこ');
      expect(results.length, 1);
      expect(results.first.id, 'p3');
    });

    test('filters by language code when specified', () {
      final results = filterMemories('aklat', languageCode: 'ja');
      expect(results, isEmpty);

      final filResults = filterMemories('aklat', languageCode: 'fil');
      expect(filResults.length, 1);
    });

    test('returns all polaroids when query is empty', () {
      final results = filterMemories('');
      expect(results.length, samplePolaroids.length);
    });
  });
}
