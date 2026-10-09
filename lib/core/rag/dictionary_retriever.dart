import '../languages/baybayin_engine.dart';
import 'models/lexicon_entry.dart';

class DictionaryRetriever {
  static final Map<String, List<LexiconEntry>> _japaneseLexicon = {
    'cup': [
      const LexiconEntry(
        labelEn: 'Cup',
        languageCode: 'ja',
        targetWord: 'マグカップ',
        secondaryScript: 'まぐかっぷ',
        transliteration: 'magukappu',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: '温かい珈琲を飲む',
        phraseTranslation: 'Drink warm coffee',
      ),
      const LexiconEntry(
        labelEn: 'Glass / Cup',
        languageCode: 'ja',
        targetWord: 'コップ',
        secondaryScript: 'こっぷ',
        transliteration: 'koppu',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: 'コップに水を注ぐ',
        phraseTranslation: 'Pour water into a cup',
      ),
    ],
    'coffee': [
      const LexiconEntry(
        labelEn: 'Coffee',
        languageCode: 'ja',
        targetWord: '珈琲',
        secondaryScript: 'こーひー',
        transliteration: 'koohii',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: '珈琲の香りがいい',
        phraseTranslation: 'The coffee smells good',
      ),
    ],
    'book': [
      const LexiconEntry(
        labelEn: 'Book',
        languageCode: 'ja',
        targetWord: '本',
        secondaryScript: 'ほん',
        transliteration: 'hon',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: '本を読むのが好きです',
        phraseTranslation: 'I like reading books',
      ),
    ],
    'desk': [
      const LexiconEntry(
        labelEn: 'Desk / Table',
        languageCode: 'ja',
        targetWord: '机',
        secondaryScript: 'つくえ',
        transliteration: 'tsukue',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: '机の上に置く',
        phraseTranslation: 'Place on the desk',
      ),
    ],
    'table': [
      const LexiconEntry(
        labelEn: 'Table',
        languageCode: 'ja',
        targetWord: 'テーブル',
        secondaryScript: 'てーぶる',
        transliteration: 'teeburu',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: 'テーブルを拭く',
        phraseTranslation: 'Wipe the table',
      ),
    ],
    'cat': [
      const LexiconEntry(
        labelEn: 'Cat',
        languageCode: 'ja',
        targetWord: '猫',
        secondaryScript: 'ねこ',
        transliteration: 'neko',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: '可愛い猫がいる',
        phraseTranslation: 'There is a cute cat',
      ),
    ],
    'chair': [
      const LexiconEntry(
        labelEn: 'Chair',
        languageCode: 'ja',
        targetWord: '椅子',
        secondaryScript: 'いす',
        transliteration: 'isu',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: '椅子に座る',
        phraseTranslation: 'Sit on the chair',
      ),
    ],
    'pen': [
      const LexiconEntry(
        labelEn: 'Pen',
        languageCode: 'ja',
        targetWord: 'ペン',
        secondaryScript: 'ぺん',
        transliteration: 'pen',
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
        examplePhrase: 'ペンでメモを書く',
        phraseTranslation: 'Write notes with a pen',
      ),
    ],
  };

  static final Map<String, List<LexiconEntry>> _filipinoLexicon = {
    'book': [
      LexiconEntry(
        labelEn: 'Book',
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('aklat'), // ᜀᜃ᜔ᜎᜆ᜔
        secondaryScript: 'aklat',
        transliteration: '[ak-lat]',
        partOfSpeech: 'Pangngalan (Noun)',
        difficultyLevel: 'A1',
        examplePhrase: 'Magbasa ng aklat',
        phraseTranslation: 'Read a book',
      ),
    ],
    'cup': [
      LexiconEntry(
        labelEn: 'Cup / Mug',
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('tasa'), // ᜆᜐ
        secondaryScript: 'tasa',
        transliteration: '[ta-sa]',
        partOfSpeech: 'Pangngalan (Noun)',
        difficultyLevel: 'A1',
        examplePhrase: 'Mainit na kape sa tasa',
        phraseTranslation: 'Hot coffee in the cup',
      ),
    ],
    'coffee': [
      LexiconEntry(
        labelEn: 'Coffee',
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('kape'), // ᜃᜉᜒ
        secondaryScript: 'kape',
        transliteration: '[ka-pe]',
        partOfSpeech: 'Pangngalan (Noun)',
        difficultyLevel: 'A1',
        examplePhrase: 'Masarap ang kape tuwing umaga',
        phraseTranslation: 'Coffee is delicious in the morning',
      ),
    ],
    'desk': [
      LexiconEntry(
        labelEn: 'Desk / Table',
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('mesa'), // ᜋᜒᜐ
        secondaryScript: 'mesa',
        transliteration: '[me-sa]',
        partOfSpeech: 'Pangngalan (Noun)',
        difficultyLevel: 'A1',
        examplePhrase: 'Ilagay sa ibabaw ng mesa',
        phraseTranslation: 'Place on top of the desk',
      ),
    ],
    'cat': [
      LexiconEntry(
        labelEn: 'Cat',
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('pusa'), // ᜉᜓᜐ
        secondaryScript: 'pusa',
        transliteration: '[pu-sa]',
        partOfSpeech: 'Pangngalan (Noun)',
        difficultyLevel: 'A1',
        examplePhrase: 'Maamong pusa',
        phraseTranslation: 'Gentle cat',
      ),
    ],
    'chair': [
      LexiconEntry(
        labelEn: 'Chair',
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('silya'), // ᜐᜒᜎ᜔ᜌ
        secondaryScript: 'silya',
        transliteration: '[sil-ya]',
        partOfSpeech: 'Pangngalan (Noun)',
        difficultyLevel: 'A1',
        examplePhrase: 'Umupo sa silya',
        phraseTranslation: 'Sit on the chair',
      ),
    ],
    'flower': [
      LexiconEntry(
        labelEn: 'Flower',
        languageCode: 'fil',
        targetWord: BaybayinEngine.transliterate('bulaklak'), // ᜊᜓᜎᜃ᜔ᜎᜃ᜔
        secondaryScript: 'bulaklak',
        transliteration: '[bu-lak-lak]',
        partOfSpeech: 'Pangngalan (Noun)',
        difficultyLevel: 'A1',
        examplePhrase: 'Mabangong bulaklak',
        phraseTranslation: 'Fragrant flower',
      ),
    ],
  };

  /// Retrieves grounded pedagogical lexicon entries for a given label and target language
  List<LexiconEntry> retrieve(String labelEn, String languageCode) {
    final clean = labelEn.trim().toLowerCase();
    final Map<String, List<LexiconEntry>> bank = languageCode == 'fil'
        ? _filipinoLexicon
        : (languageCode == 'ja' ? _japaneseLexicon : {});

    // Exact key match
    if (bank.containsKey(clean)) {
      return bank[clean]!;
    }

    // Substring / word match (e.g., "coffee cup" matches "cup" and "coffee")
    final matches = <LexiconEntry>[];
    for (final entry in bank.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        matches.addAll(entry.value);
      }
    }

    if (matches.isNotEmpty) {
      return matches;
    }

    // Fallback: If Filipino, auto-generate deterministic Baybayin entry on the fly
    if (languageCode == 'fil') {
      return [
        LexiconEntry(
          labelEn: labelEn,
          languageCode: 'fil',
          targetWord: BaybayinEngine.transliterate(labelEn),
          secondaryScript: labelEn.toLowerCase(),
          transliteration: '[$clean]',
          difficultyLevel: 'A1',
          examplePhrase: 'Isang $clean',
          phraseTranslation: 'A $clean',
        )
      ];
    }

    return const [];
  }
}
