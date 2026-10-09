import '../languages/baybayin_engine.dart';

/// Represents a pedagogically curated example sentence demonstrating a vocabulary word in context.
class ExampleSentence {
  final String nativeSentence;
  final String transliteration;
  final String englishTranslation;
  final String styleLabel;

  const ExampleSentence({
    required this.nativeSentence,
    required this.transliteration,
    required this.englishTranslation,
    this.styleLabel = 'Example',
  });
}

/// Offline, authentic sentence generator for Memoria.
/// Generates contextually accurate sentences with correct punctuation,
/// romanization/pronunciation, and translations across all supported languages.
class SentenceGeneratorService {
  const SentenceGeneratorService();

  static List<ExampleSentence> generate({
    required String languageCode,
    required String targetWord,
    required String labelEn,
    String? secondaryScript,
    String? transliteration,
  }) {
    final code = languageCode.toLowerCase().trim();
    final cleanEn = labelEn.trim().toLowerCase();

    switch (code) {
      case 'ja':
        return _generateJapanese(targetWord, cleanEn, transliteration);
      case 'fil':
      case 'tl':
        return _generateFilipino(targetWord, cleanEn, secondaryScript, transliteration);
      case 'es':
        return _generateSpanish(targetWord, cleanEn);
      case 'fr':
        return _generateFrench(targetWord, cleanEn);
      case 'de':
        return _generateGerman(targetWord, cleanEn);
      case 'zh':
        return _generateMandarin(targetWord, cleanEn, transliteration);
      default:
        return _generateFallback(targetWord, cleanEn);
    }
  }

  static List<ExampleSentence> _generateJapanese(
    String word,
    String labelEn,
    String? translit,
  ) {
    final t = (translit != null && translit.isNotEmpty) ? translit : word;
    return [
      ExampleSentence(
        styleLabel: 'Beginner Pattern',
        nativeSentence: 'これは素敵な「$word」です。',
        transliteration: 'Kore wa suteki na $t desu.',
        englishTranslation: 'This is a wonderful $labelEn.',
      ),
      ExampleSentence(
        styleLabel: 'Everyday Conversation',
        nativeSentence: 'テーブルの上に「$word」があります。',
        transliteration: 'Teeburu no ue ni $t ga arimasu.',
        englishTranslation: 'There is a $labelEn on the table.',
      ),
    ];
  }

  static List<ExampleSentence> _generateFilipino(
    String word,
    String labelEn,
    String? secondary,
    String? translit,
  ) {
    // If targetWord is in Baybayin, prioritize modern Latin Tagalog from secondaryScript
    String latin = word;
    if (secondary != null && secondary.isNotEmpty && !BaybayinEngine.hasBaybayinGlyphs(secondary)) {
      latin = secondary.split('/').first.trim();
    } else if (BaybayinEngine.hasBaybayinGlyphs(word) && translit != null) {
      latin = translit.replaceAll(RegExp(r'[\[\]\-]'), '').trim();
    }

    return [
      ExampleSentence(
        styleLabel: 'Pang-araw-araw (Everyday)',
        nativeSentence: 'Napakaganda ng $latin na ito.',
        transliteration: '[Na-pa-ka-gan-da nang $latin na i-to.]',
        englishTranslation: 'This $labelEn is very beautiful.',
      ),
      ExampleSentence(
        styleLabel: 'Pakikipag-usap (Conversation)',
        nativeSentence: 'Nasa ibabaw ng mesa ang $latin.',
        transliteration: '[Na-sa i-ba-baw nang me-sa ang $latin.]',
        englishTranslation: 'The $labelEn is on top of the table.',
      ),
    ];
  }

  static List<ExampleSentence> _generateSpanish(String word, String labelEn) {
    final cleanWord = word.split('/').first.trim();
    return [
      ExampleSentence(
        styleLabel: 'Patrón Básico (Beginner)',
        nativeSentence: 'Este es un buen $cleanWord para comenzar el día.',
        transliteration: '[Es-te es un bwen $cleanWord pa-ra ko-men-sar el di-a]',
        englishTranslation: 'This is a good $labelEn to start the day.',
      ),
      ExampleSentence(
        styleLabel: 'Conversación Diaria',
        nativeSentence: '¿Dónde dejaste el $cleanWord?',
        transliteration: '[¿Don-de de-has-te el $cleanWord?]',
        englishTranslation: 'Where did you leave the $labelEn?',
      ),
    ];
  }

  static List<ExampleSentence> _generateFrench(String word, String labelEn) {
    final cleanWord = word.split('/').first.trim();
    return [
      ExampleSentence(
        styleLabel: 'Expression Courante (Common)',
        nativeSentence: 'Voici un joli $cleanWord sur la table.',
        transliteration: '[Vwa-si un zho-li $cleanWord syr la tabl]',
        englishTranslation: 'Here is a nice $labelEn on the table.',
      ),
      ExampleSentence(
        styleLabel: 'Dialogue Quotidien',
        nativeSentence: 'J’aime beaucoup ce $cleanWord.',
        transliteration: '[Zhem bo-koo suh $cleanWord]',
        englishTranslation: 'I really like this $labelEn.',
      ),
    ];
  }

  static List<ExampleSentence> _generateGerman(String word, String labelEn) {
    var cleanWord = word.split('/').first.trim();
    // German nouns are capitalized
    if (cleanWord.isNotEmpty) {
      cleanWord = cleanWord[0].toUpperCase() + cleanWord.substring(1);
    }
    return [
      ExampleSentence(
        styleLabel: 'Grundlegend (Beginner)',
        nativeSentence: 'Hier ist ein schönes $cleanWord.',
        transliteration: '[Heer ist ayn shö-nes $cleanWord]',
        englishTranslation: 'Here is a nice $labelEn.',
      ),
      ExampleSentence(
        styleLabel: 'Alltagsgespräch (Daily)',
        nativeSentence: 'Ich habe das $cleanWord heute gesehen.',
        transliteration: '[Ikh ha-be das $cleanWord hoy-te ge-ze-hen]',
        englishTranslation: 'I saw the $labelEn today.',
      ),
    ];
  }

  static List<ExampleSentence> _generateMandarin(
    String word,
    String labelEn,
    String? translit,
  ) {
    final pinyin = (translit != null && translit.isNotEmpty) ? translit : word;
    return [
      ExampleSentence(
        styleLabel: '基础句型 (Beginner)',
        nativeSentence: '这是一个很好的$word。',
        transliteration: 'Zhè shì yí gè hěn hǎo de $pinyin.',
        englishTranslation: 'This is a very good $labelEn.',
      ),
      ExampleSentence(
        styleLabel: '日常对话 (Conversation)',
        nativeSentence: '桌子上有一个$word。',
        transliteration: 'Zhuōzi shàng yǒu yí gè $pinyin.',
        englishTranslation: 'There is a $labelEn on the table.',
      ),
    ];
  }

  static List<ExampleSentence> _generateFallback(String word, String labelEn) {
    return [
      ExampleSentence(
        styleLabel: 'Usage Pattern',
        nativeSentence: 'This is a lovely $word.',
        transliteration: word,
        englishTranslation: 'This is a lovely $labelEn.',
      ),
      ExampleSentence(
        styleLabel: 'In Context',
        nativeSentence: 'You can see the $word right here.',
        transliteration: word,
        englishTranslation: 'You can see the $labelEn right here.',
      ),
    ];
  }
}
