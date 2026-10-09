import '../../data/repositories/polaroid_repository.dart';
import 'models/memory_history_entry.dart';

class MemoryRetriever {
  final PolaroidRepository repository;

  MemoryRetriever({required this.repository});

  Future<MemoryHistoryEntry?> retrieveHistory({
    required String labelEn,
    required String languageCode,
  }) async {
    // Utilize indexed database query for object label match
    final matching = await repository.findPolaroidsByObjectLabel(
      labelEn,
      languageCode: languageCode,
    );

    if (matching.isEmpty) return null;

    final first = matching.first;
    final last = matching.last;

    return MemoryHistoryEntry(
      labelEn: labelEn,
      timesEncountered: matching.length,
      firstCapturedAt: first.createdAt,
      lastCapturedAt: last.createdAt,
      lastWordLearned: last.selectedWord,
    );
  }
}

