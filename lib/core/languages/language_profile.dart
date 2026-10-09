import 'package:world_flags/world_flags.dart';
import '../../domain/models/detected_object.dart';

enum ChinLayoutStrategy {
  /// Line 1: Kanji/Kana, Line 2: Reading kana · Romaji
  kanjiFirst,

  /// Line 1: Baybayin script, Line 2: Modern Latin Tagalog · [pronunciation]
  baybayinFirst,

  /// Line 1: Modern Latin word, Line 2: Pronunciation · part of speech
  standardLatin,
}

class LanguageProfile {
  final String code;
  final String displayName;
  final String englishName;
  final String flagEmoji;
  final WorldCountry? country;
  final bool isFocusLanguage;
  final String primaryFontFamily;
  final List<String> fontFallbacks;
  final ChinLayoutStrategy chinLayout;
  final String promptInstructions;
  final String ttsLocale;
  final bool Function(DetectedObject obj)? validator;

  const LanguageProfile({
    required this.code,
    required this.displayName,
    required this.englishName,
    required this.flagEmoji,
    this.country,
    this.isFocusLanguage = false,
    required this.primaryFontFamily,
    this.fontFallbacks = const [],
    this.chinLayout = ChinLayoutStrategy.standardLatin,
    required this.promptInstructions,
    required this.ttsLocale,
    this.validator,
  });
}

class LanguageRegistry {
  // Tier 1: Focus Languages
  static const LanguageProfile japanese = LanguageProfile(
    code: 'ja',
    displayName: '日本語',
    englishName: 'Japanese',
    flagEmoji: '🇯🇵',
    country: CountryJpn(),
    isFocusLanguage: true,
    primaryFontFamily: 'Yusei Magic',
    fontFallbacks: ['Noto Sans JP', 'sans-serif'],
    chinLayout: ChinLayoutStrategy.kanjiFirst,
    promptInstructions:
        'Target Language: Japanese. '
        'For each detected object: '
        'target_word must be the standard Japanese writing (kanji/kana, e.g. 本, 猫, コップ). '
        'secondary_script must be the full hiragana reading (e.g. ほん, ねこ, こっぷ). '
        'transliteration must be Hepburn romaji (e.g. hon, neko, koppu). '
        'difficulty_level must be JLPT N5 to N1 (favor N5/N4 for common everyday items). '
        'Always pick the most common everyday beginner word, not rare synonyms.',
    ttsLocale: 'ja-JP',
  );

  static const LanguageProfile filipino = LanguageProfile(
    code: 'fil',
    displayName: 'Filipino (Baybayin)',
    englishName: 'Filipino',
    flagEmoji: '🇵🇭',
    country: CountryPhl(),
    isFocusLanguage: true,
    primaryFontFamily: 'Baybayin Sisil',
    fontFallbacks: ['Noto Sans Tagalog', 'sans-serif'],
    chinLayout: ChinLayoutStrategy.baybayinFirst,
    promptInstructions:
        'Target Language: Filipino / Tagalog. '
        'For each detected object: '
        'target_word must be the authentic Baybayin Unicode script characters (Unicode range U+1700 to U+171F, e.g. ᜀᜃᜎᜆ᜔ for aklat, ᜉᜓᜐ for pusa, ᜋᜒᜐ for mesa). '
        'secondary_script must be the modern Latin Tagalog word (e.g. aklat, pusa, mesa). '
        'transliteration must be phonetic pronunciation guide with hyphenated syllables (e.g. [ak-lat], [pu-sa], [me-sa]). '
        'difficulty_level must be CEFR A1 to B2 (favor A1/A2 for common items). '
        'Always pick the most common everyday beginner word.',
    ttsLocale: 'fil-PH',
  );

  // Tier 2: Presets
  static const LanguageProfile spanish = LanguageProfile(
    code: 'es',
    displayName: 'Español',
    englishName: 'Spanish',
    flagEmoji: '🇪🇸',
    country: CountryEsp(),
    primaryFontFamily: 'Caveat',
    chinLayout: ChinLayoutStrategy.standardLatin,
    promptInstructions:
        'Target Language: Spanish. target_word is the common noun (e.g. libro, gato, taza). secondary_script is the article + noun (e.g. el libro). transliteration is phonetic pronunciation guide. Level CEFR A1-C1.',
    ttsLocale: 'es-ES',
  );

  static const LanguageProfile french = LanguageProfile(
    code: 'fr',
    displayName: 'Français',
    englishName: 'French',
    flagEmoji: '🇫🇷',
    country: CountryFra(),
    primaryFontFamily: 'Caveat',
    chinLayout: ChinLayoutStrategy.standardLatin,
    promptInstructions:
        'Target Language: French. target_word is the common noun (e.g. livre, chat, tasse). secondary_script is the gender article + noun (e.g. le livre). transliteration is phonetic guide.',
    ttsLocale: 'fr-FR',
  );

  static const LanguageProfile german = LanguageProfile(
    code: 'de',
    displayName: 'Deutsch',
    englishName: 'German',
    flagEmoji: '🇩🇪',
    country: CountryDeu(),
    primaryFontFamily: 'Caveat',
    chinLayout: ChinLayoutStrategy.standardLatin,
    promptInstructions:
        'Target Language: German. target_word is capitalized noun. secondary_script is gender marker (der/die/das). transliteration is phonetic guide.',
    ttsLocale: 'de-DE',
  );

  static const LanguageProfile mandarin = LanguageProfile(
    code: 'zh',
    displayName: '中文',
    englishName: 'Mandarin Chinese',
    flagEmoji: '🇨🇳',
    country: CountryChn(),
    primaryFontFamily: 'Noto Sans SC',
    chinLayout: ChinLayoutStrategy.kanjiFirst,
    promptInstructions:
        'Target Language: Mandarin Chinese (Simplified). target_word is Hanzi characters. secondary_script is Pinyin with tonal markers. transliteration is pronunciation guide.',
    ttsLocale: 'zh-CN',
  );

  static List<LanguageProfile> get focusLanguages => [japanese, filipino];

  static List<LanguageProfile> get presets => [
        japanese,
        filipino,
        spanish,
        french,
        german,
        mandarin,
      ];

  static LanguageProfile findByCode(String code) {
    for (final p in presets) {
      if (p.code.toLowerCase() == code.toLowerCase()) {
        return p;
      }
    }
    // Dynamic fallback for custom language
    return createDynamicProfile(code);
  }

  static LanguageProfile createDynamicProfile(String codeOrName) {
    final country = WorldCountry.maybeFromAnyCode(codeOrName);
    return LanguageProfile(
      code: codeOrName.toLowerCase(),
      displayName: codeOrName,
      englishName: codeOrName,
      flagEmoji: '🌐',
      country: country,
      primaryFontFamily: 'Caveat',
      promptInstructions:
          'Target Language: $codeOrName. Provide target_word in native script, secondary_script in standard script or reading, and transliteration in Latin phonetic pronunciation.',
      ttsLocale: codeOrName.length == 2 ? '${codeOrName.toLowerCase()}-${codeOrName.toUpperCase()}' : 'en-US',
    );
  }
}
