class LexiconEntry {
  final String labelEn;
  final String languageCode;
  final String targetWord;
  final String secondaryScript;
  final String transliteration;
  final String partOfSpeech;
  final String difficultyLevel;
  final String examplePhrase;
  final String phraseTranslation;

  const LexiconEntry({
    required this.labelEn,
    required this.languageCode,
    required this.targetWord,
    required this.secondaryScript,
    required this.transliteration,
    this.partOfSpeech = 'Noun',
    required this.difficultyLevel,
    required this.examplePhrase,
    required this.phraseTranslation,
  });
}
