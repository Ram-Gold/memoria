import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/rag/dictionary_retriever.dart';
import 'package:memoria/core/rag/memory_retriever.dart';
import 'package:memoria/core/rag/rag_service.dart';
import 'package:memoria/data/repositories/polaroid_repository.dart';
import 'package:memoria/domain/models/analysis_result.dart';
import 'package:memoria/domain/models/detected_object.dart';
import 'package:memoria/domain/models/polaroid.dart';

class FakePolaroidRepository extends PolaroidRepository {
  final List<Polaroid> _items = [];

  void add(Polaroid p) => _items.add(p);

  @override
  Future<List<Polaroid>> getAllPolaroids() async => List.unmodifiable(_items);

  @override
  Future<List<Polaroid>> findPolaroidsByObjectLabel(String labelEn, {String? languageCode}) async {
    final clean = labelEn.trim().toLowerCase();
    return _items.where((p) {
      if (languageCode != null && p.languageCode != languageCode) return false;
      return p.detectedObjects.any((o) => o.labelEn.toLowerCase().contains(clean));
    }).toList();
  }

  @override
  Future<List<Polaroid>> searchPolaroids(String query, {String? languageCode}) async {
    final clean = query.trim().toLowerCase();
    return _items.where((p) {
      if (languageCode != null && p.languageCode != languageCode) return false;
      return p.selectedWord.toLowerCase().contains(clean) ||
          (p.secondaryScript?.toLowerCase().contains(clean) ?? false) ||
          (p.transliteration?.toLowerCase().contains(clean) ?? false) ||
          p.detectedObjects.any((o) => o.labelEn.toLowerCase().contains(clean));
    }).toList();
  }
}

void main() {
  group('DictionaryRetriever RAG Tests', () {
    final retriever = DictionaryRetriever();

    test('retrieves Japanese dictionary ground truth for cup', () {
      final results = retriever.retrieve('cup', 'ja');
      expect(results, isNotEmpty);
      expect(results.first.targetWord, 'マグカップ');
      expect(results.first.difficultyLevel, 'N5');
      expect(results.first.examplePhrase, isNotEmpty);
    });

    test('retrieves Japanese dictionary ground truth for coffee', () {
      final results = retriever.retrieve('coffee', 'ja');
      expect(results, isNotEmpty);
      expect(results.first.targetWord, '珈琲');
      expect(results.first.transliteration, 'koohii');
    });

    test('retrieves Filipino Baybayin ground truth for aklat / book', () {
      final results = retriever.retrieve('book', 'fil');
      expect(results, isNotEmpty);
      expect(results.first.secondaryScript, 'aklat');
      expect(results.first.targetWord, contains('\u1700')); // Baybayin 'a'
      expect(results.first.examplePhrase, contains('aklat'));
    });

    test('handles fallback on-the-fly generation for unknown Filipino words', () {
      final results = retriever.retrieve('banana', 'fil');
      expect(results, isNotEmpty);
      expect(results.first.languageCode, 'fil');
      expect(results.first.secondaryScript, 'banana');
    });
  });

  group('MemoryRetriever & Spaced Memory Recall Tests', () {
    test('returns null when no history exists', () async {
      final fakeRepo = FakePolaroidRepository();
      final retriever = MemoryRetriever(repository: fakeRepo);

      final history = await retriever.retrieveHistory(labelEn: 'coffee', languageCode: 'ja');
      expect(history, isNull);
    });

    test('retrieves accurate history when past polaroids exist', () async {
      final fakeRepo = FakePolaroidRepository();
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));

      fakeRepo.add(
        Polaroid(
          id: 'pol-1',
          imagePath: '/tmp/pol1.jpg',
          outputImagePath: '/tmp/pol1.jpg',
          languageCode: 'ja',
          selectedObjectId: 'obj-1',
          selectedWord: '珈琲',
          createdAt: twoDaysAgo,
          detectedObjects: const [
            DetectedObject(
              id: 'obj-1',
              labelEn: 'Coffee',
              targetWord: '珈琲',
              box: [0, 0, 100, 100],
            ),
          ],
        ),
      );

      final retriever = MemoryRetriever(repository: fakeRepo);
      final history = await retriever.retrieveHistory(labelEn: 'coffee', languageCode: 'ja');

      expect(history, isNotNull);
      expect(history!.timesEncountered, 1);
      expect(history.lastWordLearned, '珈琲');
      expect(history.daysSinceLastEncounter, greaterThanOrEqualTo(2));
    });
  });

  group('RagService Augmentation Tests', () {
    test('augments raw analysis result with dictionary and history', () async {
      final fakeRepo = FakePolaroidRepository();
      fakeRepo.add(
        Polaroid(
          id: 'pol-1',
          imagePath: '/tmp/pol1.jpg',
          outputImagePath: '/tmp/pol1.jpg',
          languageCode: 'ja',
          selectedObjectId: 'obj-1',
          selectedWord: '本',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          detectedObjects: const [
            DetectedObject(
              id: 'obj-1',
              labelEn: 'Book',
              targetWord: '本',
              box: [0, 0, 100, 100],
            ),
          ],
        ),
      );


      final ragService = RagService(repository: fakeRepo);
      const rawResult = AnalysisResult(
        sessionId: 'test_session',
        languageCode: 'ja',
        primaryObjectId: 'obj-1',
        sceneDescription: 'A book on a desk',
        detectedObjects: [
          DetectedObject(
            id: 'obj-1',
            labelEn: 'Book',
            targetWord: 'ほん',
            box: [0, 0, 100, 100],
          ),
        ],
      );

      final augmented = await ragService.augment(
        rawResult: rawResult,
        languageCode: 'ja',
      );

      expect(augmented.ragContext, isNotNull);
      expect(augmented.ragContext!.hasLexicon, isTrue);
      expect(augmented.ragContext!.hasHistory, isTrue);
      expect(augmented.ragContext!.recallHeadline, contains('Memory Recall'));
      expect(augmented.ragContext!.recommendedCollocation, isNotNull);

      // Verify primary object enriched with authoritative lexicon ground truth
      final enrichedPrimary = augmented.primaryObject;
      expect(enrichedPrimary, isNotNull);
      expect(enrichedPrimary!.targetWord, '本'); // Enriched from lexicon
      expect(enrichedPrimary.difficultyLevel, 'N5');
    });
  });
}
