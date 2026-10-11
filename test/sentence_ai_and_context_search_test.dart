import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memoria/core/languages/sentence_generator.dart';
import 'package:memoria/core/services/context_search_service.dart';
import 'package:memoria/core/services/sentence_ai_service.dart';
import 'package:memoria/core/services/tatoeba_corpus_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContextSearchService', () {
    test('openGoogleSearch builds correct quoted search URL', () async {
      final url = ContextSearchService.buildGoogleSearchUri('喫茶店', 'ja');
      expect(url.toString(), contains('google.com/search'));
      expect(url.queryParameters['q'], equals('"喫茶店"'));
      expect(url.queryParameters['hl'], equals('ja'));
    });

    test('buildContextDictionaryUrl routes to dedicated dictionaries by language', () {
      final jaUrl = ContextSearchService.buildContextDictionaryUri('猫', 'ja');
      expect(jaUrl.host, contains('jisho.org'));
      expect(ContextSearchService.getDictionaryName('ja'), equals('Dictionary'));

      final tlUrl = ContextSearchService.buildContextDictionaryUri('pusa', 'tl');
      expect(tlUrl.host, contains('tagalog.com'));
      expect(ContextSearchService.getDictionaryName('tl'), equals('Dictionary'));

      final esUrl = ContextSearchService.buildContextDictionaryUri('gato', 'es');
      expect(esUrl.host, contains('reverso.net'));
      expect(ContextSearchService.getDictionaryName('es'), equals('Dictionary'));

      final zhUrl = ContextSearchService.buildContextDictionaryUri('猫', 'zh');
      expect(zhUrl.host, contains('mdbg.net'));
      expect(ContextSearchService.getDictionaryName('zh'), equals('Dictionary'));

      final fallbackUrl = ContextSearchService.buildContextDictionaryUri('test', 'it');
      expect(fallbackUrl.host, contains('wiktionary.org'));
      expect(ContextSearchService.getDictionaryName('it'), equals('Dictionary'));
    });

    test('buildGoogleTranslateUrl creates correct translation link', () {
      final url = ContextSearchService.buildGoogleTranslateUri('gato', 'es');
      expect(url.host, contains('translate.google.com'));
      expect(url.queryParameters['sl'], equals('es'));
      expect(url.queryParameters['tl'], equals('en'));
      expect(url.queryParameters['text'], equals('gato'));
    });
  });

  group('SentenceAiService & Fallback Generator', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('generates robust fallback sentences when API key is empty', () async {
      final service = SentenceAiService();
      final sentences = await service.generateSentences(
        apiKey: '',
        languageCode: 'ja',
        targetWord: '喫茶店',
        labelEn: 'Cafe',
        transliteration: 'kissaten',
      );

      expect(sentences, isNotEmpty);
      expect(sentences.first.nativeSentence, contains('喫茶店'));
      expect(sentences.first.englishTranslation, isNotEmpty);
      expect(sentences.first.styleLabel, isNotEmpty);
    });

    test('SentenceGeneratorService generates natural offline sentences across languages', () {
      final esSentences = SentenceGeneratorService.generate(
        targetWord: 'manzana',
        labelEn: 'Apple',
        languageCode: 'es',
      );
      expect(esSentences, isNotEmpty);
      expect(esSentences.first.nativeSentence, contains('manzana'));
      expect(esSentences.first.englishTranslation.toLowerCase(), contains('apple'));

      final frSentences = SentenceGeneratorService.generate(
        targetWord: 'pomme',
        labelEn: 'Apple',
        languageCode: 'fr',
      );
      expect(frSentences, isNotEmpty);
      expect(frSentences.first.nativeSentence, contains('pomme'));

      final deSentences = SentenceGeneratorService.generate(
        targetWord: 'Buch',
        labelEn: 'Book',
        languageCode: 'de',
      );
      expect(deSentences, isNotEmpty);
      expect(deSentences.first.nativeSentence, contains('Buch'));
    });
  });

  group('TatoebaCorpusService', () {
    test('maps language codes to ISO-639-3 correctly', () {
      expect(TatoebaCorpusService.mapLanguageCode('ja'), equals('jpn'));
      expect(TatoebaCorpusService.mapLanguageCode('es'), equals('spa'));
      expect(TatoebaCorpusService.mapLanguageCode('fr'), equals('fra'));
      expect(TatoebaCorpusService.mapLanguageCode('de'), equals('deu'));
      expect(TatoebaCorpusService.mapLanguageCode('tl'), equals('tgl'));
      expect(TatoebaCorpusService.mapLanguageCode('fil'), equals('tgl'));
      expect(TatoebaCorpusService.mapLanguageCode('zh'), equals('cmn'));
    });

    test('fetches and filters real corpus sentences via mock client', () async {
      SharedPreferences.setMockInitialValues({});

      // Mock response simulating Tatoeba sentences JSON
      final mockJson = '''
      {
        "data": [
          {
            "id": 10550428,
            "text": "喫茶店に行きたい？",
            "lang": "jpn",
            "translations": [
              {
                "id": 10550404,
                "text": "Do you want to go to a coffee shop?",
                "lang": "eng"
              }
            ]
          },
          {
            "id": 11574850,
            "text": "This is a profane sentence with fuck in it.",
            "lang": "jpn",
            "translations": [
              {
                "id": 1234,
                "text": "Bad sentence",
                "lang": "eng"
              }
            ]
          }
        ]
      }
      ''';

      // We use a mock HTTP client
      final mockClient = _MockHttpClient(mockJson, 200);
      final service = TatoebaCorpusService(client: mockClient);

      final results = await service.fetchCorpusSentences(
        languageCode: 'ja',
        targetWord: '喫茶店',
      );

      expect(results, hasLength(1));
      expect(results.first.nativeSentence, equals('喫茶店に行きたい？'));
      expect(results.first.englishTranslation, equals('Do you want to go to a coffee shop?'));
      expect(results.first.styleLabel, equals('Example'));

      // Check cache retrieval
      final cachedResults = await service.fetchCorpusSentences(
        languageCode: 'ja',
        targetWord: '喫茶店',
      );
      expect(cachedResults, hasLength(1));
      expect(cachedResults.first.nativeSentence, equals('喫茶店に行きたい？'));
    });
  });
}

class _MockHttpClient extends Fake implements http.Client {
  final String responseBody;
  final int statusCode;

  _MockHttpClient(this.responseBody, this.statusCode);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return http.Response.bytes(
      utf8.encode(responseBody),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
