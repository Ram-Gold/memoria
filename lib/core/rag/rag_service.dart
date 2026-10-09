import '../../data/repositories/polaroid_repository.dart';
import '../../data/services/local_object_lexicon.dart';
import '../../domain/models/analysis_result.dart';
import 'dictionary_retriever.dart';
import 'memory_retriever.dart';
import 'models/rag_context.dart';

class RagService {
  final DictionaryRetriever _dictionaryRetriever;
  final MemoryRetriever _memoryRetriever;

  RagService({
    DictionaryRetriever? dictionaryRetriever,
    required PolaroidRepository repository,
  })  : _dictionaryRetriever = dictionaryRetriever ?? DictionaryRetriever(),
        _memoryRetriever = MemoryRetriever(repository: repository);

  /// Retrieves pedagogical dictionary ground truth and personal memory history
  Future<RagContext> retrieveContext({
    required String labelEn,
    required String languageCode,
  }) async {
    final lexicon = _dictionaryRetriever.retrieve(labelEn, languageCode);
    final history = await _memoryRetriever.retrieveHistory(
      labelEn: labelEn,
      languageCode: languageCode,
    );

    String? recallHeadline;
    if (history != null && history.timesEncountered > 0) {
      final days = history.daysSinceLastEncounter;
      if (days == 0) {
        recallHeadline = 'Memory Recall: You previously captured this today! (${history.timesEncountered + 1}th encounter)';
      } else {
        recallHeadline = 'Memory Recall: Captured ${history.timesEncountered} time(s) before ($days days ago)';
      }
    }

    String? collocation;
    String? translation;
    if (lexicon.isNotEmpty) {
      collocation = lexicon.first.examplePhrase;
      translation = lexicon.first.phraseTranslation;
    }

    return RagContext(
      retrievedLexicon: lexicon,
      history: history,
      recallHeadline: recallHeadline,
      recommendedCollocation: collocation,
      phraseTranslation: translation,
    );
  }

  /// Ground and augment the raw AI vision analysis result with retrieved context
  Future<AnalysisResult> augment({
    required AnalysisResult rawResult,
    required String languageCode,
  }) async {
    final primary = rawResult.primaryObject;
    var label = primary?.labelEn ?? 'object';

    // If label is generic or empty, recover from dictionary using targetWord/transliteration
    if (label.isEmpty || label.toLowerCase() == 'object' || label.toLowerCase() == 'item') {
      if (primary != null) {
        final rev = LocalObjectLexicon.reverseLookup(
          targetWord: primary.targetWord,
          transliteration: primary.transliteration,
          secondaryScript: primary.secondaryScript,
          langCode: languageCode,
        );
        if (rev != null && rev.labelEn.isNotEmpty) {
          label = rev.labelEn;
        }
      }
    }

    final context = await retrieveContext(
      labelEn: label,
      languageCode: languageCode,
    );

    // If dictionary has authoritative ground truth for this object, refine missing or sub-optimal fields
    var objects = rawResult.detectedObjects;
    if (context.hasLexicon) {
      final match = context.retrievedLexicon.first;
      objects = objects.map((obj) {
        if (obj.id == rawResult.primaryObjectId) {
          return obj.copyWith(
            labelEn: match.labelEn,
            targetWord: match.targetWord,
            secondaryScript: match.secondaryScript,
            transliteration: match.transliteration,
            partOfSpeech: match.partOfSpeech,
            difficultyLevel: match.difficultyLevel,
          );
        }
        return obj;
      }).toList();
    }

    return rawResult.copyWith(
      detectedObjects: objects,
      ragContext: context,
    );
  }
}
