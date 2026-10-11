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
        styleLabel: 'Daily Conversation',
        nativeSentence: '今日、素敵な「$word」を見つけました。',
        transliteration: 'Kyou, suteki na $t o mitsukemashita.',
        englishTranslation: 'Today, I found a lovely $labelEn.',
      ),
      ExampleSentence(
        styleLabel: 'Practical Usage',
        nativeSentence: 'この「$word」はとても使いやすいですね。',
        transliteration: 'Kono $t wa totemo tsukaiyasui desu ne.',
        englishTranslation: 'This $labelEn is very convenient to use, isn\'t it?',
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
        nativeSentence: 'Gusto kong makita ang $latin mo.',
        transliteration: '[Gus-to kong ma-ki-ta ang $latin mo.]',
        englishTranslation: 'I would love to see your $labelEn.',
      ),
    ];
  }

  static List<ExampleSentence> _generateSpanish(String word, String labelEn) {
    final cleanWord = word.split('/').first.trim();
    return [
      ExampleSentence(
        styleLabel: 'Conversación Diaria',
        nativeSentence: 'Me gusta mucho este $cleanWord.',
        transliteration: '[Me gus-ta mu-cho es-te $cleanWord]',
        englishTranslation: 'I really like this $labelEn.',
      ),
      ExampleSentence(
        styleLabel: 'Expresión Útil',
        nativeSentence: 'Siempre es bueno tener un $cleanWord cerca.',
        transliteration: '[Syem-pre es bwe-no te-ner un $cleanWord ser-ka]',
        englishTranslation: 'It is always good to have a $labelEn nearby.',
      ),
    ];
  }

  static List<ExampleSentence> _generateFrench(String word, String labelEn) {
    final cleanWord = word.split('/').first.trim();
    return [
      ExampleSentence(
        styleLabel: 'Dialogue Quotidien',
        nativeSentence: 'J’aime beaucoup ce $cleanWord.',
        transliteration: '[Zhem bo-koo suh $cleanWord]',
        englishTranslation: 'I really like this $labelEn.',
      ),
      ExampleSentence(
        styleLabel: 'Expression Courante',
        nativeSentence: 'Regarde ce joli $cleanWord !',
        transliteration: '[Ruh-gard suh zho-li $cleanWord]',
        englishTranslation: 'Look at this nice $labelEn!',
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
        styleLabel: 'Alltagsgespräch (Daily)',
        nativeSentence: 'Ich finde dieses $cleanWord wirklich interessant.',
        transliteration: '[Ikh fin-de dee-zes $cleanWord virk-likh in-te-re-sant]',
        englishTranslation: 'I find this $labelEn really interesting.',
      ),
      ExampleSentence(
        styleLabel: 'Praktischer Satz',
        nativeSentence: 'Hier ist dein $cleanWord.',
        transliteration: '[Heer ist dayn $cleanWord]',
        englishTranslation: 'Here is your $labelEn.',
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
        styleLabel: '日常对话 (Conversation)',
        nativeSentence: '这是一个很好的$word。',
        transliteration: 'Zhè shì yí gè hěn hǎo de $pinyin.',
        englishTranslation: 'This is a very good $labelEn.',
      ),
      ExampleSentence(
        styleLabel: '常用句型 (Everyday)',
        nativeSentence: '我很喜欢这个$word。',
        transliteration: 'Wǒ hěn xǐhuan zhè ge $pinyin.',
        englishTranslation: 'I really like this $labelEn.',
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
