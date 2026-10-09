import 'lexicon_entry.dart';
import 'memory_history_entry.dart';

class RagContext {
  final List<LexiconEntry> retrievedLexicon;
  final MemoryHistoryEntry? history;
  final String? recallHeadline;
  final String? recommendedCollocation;
  final String? phraseTranslation;

  const RagContext({
    this.retrievedLexicon = const [],
    this.history,
    this.recallHeadline,
    this.recommendedCollocation,
    this.phraseTranslation,
  });

  bool get hasHistory => history != null && history!.timesEncountered > 0;
  bool get hasLexicon => retrievedLexicon.isNotEmpty;
}
