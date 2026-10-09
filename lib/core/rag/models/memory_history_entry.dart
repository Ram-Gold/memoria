class MemoryHistoryEntry {
  final String labelEn;
  final int timesEncountered;
  final DateTime firstCapturedAt;
  final DateTime lastCapturedAt;
  final String lastWordLearned;

  const MemoryHistoryEntry({
    required this.labelEn,
    required this.timesEncountered,
    required this.firstCapturedAt,
    required this.lastCapturedAt,
    required this.lastWordLearned,
  });

  int get daysSinceLastEncounter {
    final diff = DateTime.now().difference(lastCapturedAt).inDays;
    return diff < 0 ? 0 : diff;
  }
}
