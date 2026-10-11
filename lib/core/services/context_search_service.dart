import 'package:url_launcher/url_launcher.dart';

/// Helper to launch contextual external language references and search tools
/// (Google Search, Reverso Context, Jisho, Tagalog.com, Google Translate).
class ContextSearchService {
  const ContextSearchService();

  /// Builds Google search URI with the target word enclosed in quotes.
  static Uri buildGoogleSearchUri(String word, String languageCode) {
    final query = '"$word"';
    return Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(query)}&hl=${languageCode.toLowerCase()}',
    );
  }

  /// Opens Google search with the target word enclosed in quotes to find native usage in the wild.
  static Future<bool> openGoogleSearch(String word, String languageCode) async {
    return await launchUrl(
      buildGoogleSearchUri(word, languageCode),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Builds context dictionary URI based on language code.
  static Uri buildContextDictionaryUri(String word, String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ja':
        return Uri.parse('https://jisho.org/search/${Uri.encodeComponent(word)}');
      case 'es':
        return Uri.parse('https://context.reverso.net/translation/spanish-english/${Uri.encodeComponent(word)}');
      case 'fr':
        return Uri.parse('https://context.reverso.net/translation/french-english/${Uri.encodeComponent(word)}');
      case 'de':
        return Uri.parse('https://context.reverso.net/translation/german-english/${Uri.encodeComponent(word)}');
      case 'fil':
      case 'tl':
        return Uri.parse('https://www.tagalog.com/dictionary/${Uri.encodeComponent(word)}');
      case 'zh':
        return Uri.parse('https://www.mdbg.net/chinese/dictionary?page=worddict&wdrst=0&wdqb=${Uri.encodeComponent(word)}');
      default:
        return Uri.parse('https://en.wiktionary.org/wiki/${Uri.encodeComponent(word)}');
    }
  }

  /// Opens the highest-rated bilingual contextual dictionary for the target language.
  static Future<bool> openContextDictionary(String word, String languageCode) async {
    return await launchUrl(
      buildContextDictionaryUri(word, languageCode),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Builds Google Translate URI with target word and source language pre-selected.
  static Uri buildGoogleTranslateUri(String word, String languageCode) {
    final code = switch (languageCode.toLowerCase()) {
      'fil' => 'tl',
      _ => languageCode.toLowerCase(),
    };
    return Uri.parse(
      'https://translate.google.com/?sl=$code&tl=en&text=${Uri.encodeComponent(word)}&op=translate',
    );
  }

  /// Opens Google Translate directly with the target word and source language pre-selected.
  static Future<bool> openGoogleTranslate(String word, String languageCode) async {
    return await launchUrl(
      buildGoogleTranslateUri(word, languageCode),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Returns user-friendly dictionary badge title.
  static String getDictionaryName(String languageCode) {
    return 'Dictionary';
  }
}
