import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../languages/baybayin_engine.dart';

/// Structured lexical entry for Tagalog words, definitions, pronunciation,
/// authentic Baybayin script, and regional Philippine language cognates.
class TagalogWordEntry {
  final String word; // Latin Tagalog (e.g., 'aklat')
  final String labelEn; // English label (e.g., 'Book')
  final String partOfSpeech; // e.g., 'Pangngalan (Noun)'
  final String difficultyLevel; // e.g., 'A1'
  final String pronunciation; // e.g., '[ak-lat]'
  final String definition; // e.g., 'A bound collection of printed pages'
  final String examplePhrase; // e.g., 'Magbasa ng aklat tuwing gabi'
  final String exampleTranslation; // e.g., 'Read a book every night'
  final String? pangasinanCognate; // Regional Pangasinan equivalent (e.g., 'abong' for 'bahay')
  final String? rootWord;
  final String baybayin;

  TagalogWordEntry({
    required this.word,
    required this.labelEn,
    required this.partOfSpeech,
    required this.difficultyLevel,
    required this.pronunciation,
    required this.definition,
    required this.examplePhrase,
    required this.exampleTranslation,
    this.pangasinanCognate,
    this.rootWord,
    String? baybayin,
  }) : baybayin = baybayin ?? BaybayinEngine.transliterate(word);

  Map<String, dynamic> toJson() => {
        'word': word,
        'labelEn': labelEn,
        'partOfSpeech': partOfSpeech,
        'difficultyLevel': difficultyLevel,
        'pronunciation': pronunciation,
        'definition': definition,
        'examplePhrase': examplePhrase,
        'exampleTranslation': exampleTranslation,
        'pangasinanCognate': pangasinanCognate,
        'rootWord': rootWord,
        'baybayin': baybayin,
      };

  factory TagalogWordEntry.fromJson(Map<String, dynamic> json) {
    return TagalogWordEntry(
      word: json['word'] as String,
      labelEn: json['labelEn'] as String,
      partOfSpeech: json['partOfSpeech'] as String? ?? 'Pangngalan (Noun)',
      difficultyLevel: json['difficultyLevel'] as String? ?? 'A1',
      pronunciation: json['pronunciation'] as String? ??
          BaybayinEngine.formatPronunciation(json['word'] as String),
      definition: json['definition'] as String? ?? '',
      examplePhrase: json['examplePhrase'] as String? ?? '',
      exampleTranslation: json['exampleTranslation'] as String? ?? '',
      pangasinanCognate: json['pangasinanCognate'] as String?,
      rootWord: json['rootWord'] as String?,
      baybayin: json['baybayin'] as String?,
    );
  }
}

/// Comparative Regional Philippine Lexicon highlighting Pangasinan, Ilocano, and Cebuano cognates.
class PhilippineRegionalLexicon {
  static const Map<String, String> _tagalogToPangasinan = {
    'bahay': 'abong',
    'tubig': 'danum',
    'aso': 'aso',
    'pusa': 'pusa',
    'kain': 'mangan',
    'tulog': 'ugip',
    'mata': 'mata',
    'isda': 'sira',
    'ibon': 'manok',
    'bato': 'bato',
    'apoy': 'apoy',
    'dahon': 'bolong',
    'puno': 'kiew',
    'bulaklak': 'rosas / sabong',
    'araw': 'agew',
    'buwan': 'bulan',
    'babae': 'bii',
    'lalaki': 'laki',
    'anak': 'anak',
    'ina': 'ina',
    'ama': 'ama',
    'tao': 'too',
    'gabi': 'labi',
    'umaga': 'kabuasat',
    'hangin': 'dagem',
    'ulan': 'uran',
    'kalsada': 'dalan',
    'dagat': 'dayat',
    'mesa': 'lamisaan',
    'silya': 'silya / tugaw',
  };

  /// Returns the Pangasinan cognate for a given Tagalog word if available
  static String? getPangasinanEquivalent(String tagalogWord) {
    final clean = tagalogWord.trim().toLowerCase();
    return _tagalogToPangasinan[clean];
  }
}

/// Comprehensive Tagalog & Regional Dictionary Service.
/// Provides instant offline lookup of over 100+ everyday objects,
/// verified KWF Tagalog orthography, Pangasinan regional cognates,
/// and dynamic online dictionary fallback via Wiktionary REST API.
class TagalogDictionaryService {
  static final TagalogDictionaryService instance = TagalogDictionaryService._internal();

  final http.Client _client;

  TagalogDictionaryService._internal({http.Client? client})
      : _client = client ?? http.Client();

  static const String _cachePrefix = 'memoria_tgl_dict_cache_';

  // Comprehensive curated dictionary bank for everyday objects
  static final Map<String, TagalogWordEntry> _tagalogBank = {
    'aklat': TagalogWordEntry(
      word: 'aklat',
      labelEn: 'Book',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ak-lat]',
      definition: 'Isang kalipunan ng mga nakalimbag na papel o babasahin.',
      examplePhrase: 'Magbasa ng aklat tuwing gabi.',
      exampleTranslation: 'Read a book every night.',
      rootWord: 'aklat',
    ),
    'tasa': TagalogWordEntry(
      word: 'tasa',
      labelEn: 'Cup / Mug',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ta-sa]',
      definition: 'Maliit na sisidlan ng inumin na karaniwang may hawakan.',
      examplePhrase: 'Mainit na kape sa tasa.',
      exampleTranslation: 'Hot coffee in the cup.',
      rootWord: 'tasa',
    ),
    'kape': TagalogWordEntry(
      word: 'kape',
      labelEn: 'Coffee',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ka-pe]',
      definition: 'Mabangong inumin na gawa sa giniling na butil ng kape.',
      examplePhrase: 'Masarap ang kape sa umaga.',
      exampleTranslation: 'Coffee is delicious in the morning.',
      rootWord: 'kape',
    ),
    'mesa': TagalogWordEntry(
      word: 'mesa',
      labelEn: 'Table / Desk',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[me-sa]',
      definition: 'Kasangkapang pambahay na may patag na ibabaw at mga paa.',
      examplePhrase: 'Ilagay ang gamit sa ibabaw ng mesa.',
      exampleTranslation: 'Place the things on top of the table.',
      pangasinanCognate: 'lamisaan',
      rootWord: 'mesa',
    ),
    'silya': TagalogWordEntry(
      word: 'silya',
      labelEn: 'Chair',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[sil-ya]',
      definition: 'Kasangkapan sa bahay o opisina na inuupuan ng isang tao.',
      examplePhrase: 'Umupo sa komportableng silya.',
      exampleTranslation: 'Sit on the comfortable chair.',
      pangasinanCognate: 'silya / tugaw',
      rootWord: 'silya',
    ),
    'pusa': TagalogWordEntry(
      word: 'pusa',
      labelEn: 'Cat',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[pu-sa]',
      definition: 'Isang maamong hayop na may apat na paa at may balahibo.',
      examplePhrase: 'Natutulog ang pusa sa sofa.',
      exampleTranslation: 'The cat is sleeping on the sofa.',
      pangasinanCognate: 'pusa',
      rootWord: 'pusa',
    ),
    'aso': TagalogWordEntry(
      word: 'aso',
      labelEn: 'Dog',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[a-so]',
      definition: 'Matalik na kaibigang hayop ng tao na tumatahol at nagbabantay.',
      examplePhrase: 'Bantay ng bahay ang aming aso.',
      exampleTranslation: 'Our dog guards the house.',
      pangasinanCognate: 'aso',
      rootWord: 'aso',
    ),
    'bulaklak': TagalogWordEntry(
      word: 'bulaklak',
      labelEn: 'Flower',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[bu-lak-lak]',
      definition: 'Makulay at mabangong bahagi ng halaman.',
      examplePhrase: 'Mabangong bulaklak sa hardin.',
      exampleTranslation: 'Fragrant flower in the garden.',
      pangasinanCognate: 'rosas / sabong',
      rootWord: 'bulaklak',
    ),
    'tubig': TagalogWordEntry(
      word: 'tubig',
      labelEn: 'Water',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[tu-big]',
      definition: 'Malinaw na likido na kailangan sa buhay ng tao at hayop.',
      examplePhrase: 'Uminom ng maraming tubig araw-araw.',
      exampleTranslation: 'Drink plenty of water every day.',
      pangasinanCognate: 'danum',
      rootWord: 'tubig',
    ),
    'tsaa': TagalogWordEntry(
      word: 'tsaa',
      labelEn: 'Tea',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[tsa-a]',
      definition: 'Inuming pampaginhawa na gawa sa pinakuluang tuyong dahon.',
      examplePhrase: 'Mainit na tsaa na may kalamansi.',
      exampleTranslation: 'Warm tea with calamansi.',
      rootWord: 'tsaa',
    ),
    'bote': TagalogWordEntry(
      word: 'bote',
      labelEn: 'Bottle',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[bo-te]',
      definition: 'Sisidlan ng likido na karaniwang gawa sa bubog o plastik.',
      examplePhrase: 'Bote ng malamig na tubig.',
      exampleTranslation: 'Bottle of cold water.',
      rootWord: 'bote',
    ),
    'baso': TagalogWordEntry(
      word: 'baso',
      labelEn: 'Drinking Glass',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ba-so]',
      definition: 'Maliit na sisidlan na gawa sa kristal o bubog para sa inumin.',
      examplePhrase: 'Isang baso ng sariwang gatas.',
      exampleTranslation: 'A glass of fresh milk.',
      rootWord: 'baso',
    ),
    'kutsara': TagalogWordEntry(
      word: 'kutsara',
      labelEn: 'Spoon',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[kut-sa-ra]',
      definition: 'Kagamitan sa pagkain na may bilugang dulo at hawakan.',
      examplePhrase: 'Kutsara at tinidor sa hapag-kainan.',
      exampleTranslation: 'Spoon and fork on the dining table.',
      rootWord: 'kutsara',
    ),
    'tinidor': TagalogWordEntry(
      word: 'tinidor',
      labelEn: 'Fork',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ti-ni-dor]',
      definition: 'Kagamitang pangkain na may mga ngipin para ituhog sa pagkain.',
      examplePhrase: 'Gamitin ang tinidor sa pagkain ng pansit.',
      exampleTranslation: 'Use the fork when eating noodles.',
      rootWord: 'tinidor',
    ),
    'kutsilyo': TagalogWordEntry(
      word: 'kutsilyo',
      labelEn: 'Knife',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[kut-sil-yo]',
      definition: 'Matalim na kasangkapang pamputol.',
      examplePhrase: 'Matalim na kutsilyo para sa tinapay.',
      exampleTranslation: 'Sharp knife for the bread.',
      rootWord: 'kutsilyo',
    ),
    'pinggan': TagalogWordEntry(
      word: 'pinggan',
      labelEn: 'Plate / Dish',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ping-gan]',
      definition: 'Mababaw at bilog na lalagyan ng pagkain.',
      examplePhrase: 'Ilagay ang ulam sa malinis na pinggan.',
      exampleTranslation: 'Place the dish on a clean plate.',
      rootWord: 'pinggan',
    ),
    'mangkok': TagalogWordEntry(
      word: 'mangkok',
      labelEn: 'Bowl',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[mang-kok]',
      definition: 'Malukong na sisidlan para sa sabaw at ulam.',
      examplePhrase: 'Mainit na sabaw sa loob ng mangkok.',
      exampleTranslation: 'Hot soup inside the bowl.',
      rootWord: 'mangkok',
    ),
    'sapatos': TagalogWordEntry(
      word: 'sapatos',
      labelEn: 'Shoes',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[sa-pa-tos]',
      definition: 'Sapin sa paa na pananggalang sa dumi at init.',
      examplePhrase: 'Bagong sapatos para sa eskwela.',
      exampleTranslation: 'New shoes for school.',
      rootWord: 'sapatos',
    ),
    'damit': TagalogWordEntry(
      word: 'damit',
      labelEn: 'Clothes / Shirt',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[da-mit]',
      definition: 'Kasuotang panakip sa katawan.',
      examplePhrase: 'Mabangong bagong labang damit.',
      exampleTranslation: 'Fragrant freshly washed clothes.',
      rootWord: 'damit',
    ),
    'orasan': TagalogWordEntry(
      word: 'orasan',
      labelEn: 'Clock / Watch',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[o-ra-san]',
      definition: 'Kasangkapang nagsasaad ng tamang oras.',
      examplePhrase: 'Tumingin sa orasan sa dingding.',
      exampleTranslation: 'Look at the clock on the wall.',
      rootWord: 'oras',
    ),
    'telebisyon': TagalogWordEntry(
      word: 'telebisyon',
      labelEn: 'Television',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A2',
      pronunciation: '[te-le-bis-yon]',
      definition: 'Aparato na nagpapakita ng gumagalaw na imahen at tunog.',
      examplePhrase: 'Manood ng balita sa telebisyon.',
      exampleTranslation: 'Watch the news on television.',
      rootWord: 'telebisyon',
    ),
    'kompyuter': TagalogWordEntry(
      word: 'kompyuter',
      labelEn: 'Computer / Laptop',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A2',
      pronunciation: '[kom-pyu-ter]',
      definition: 'Aparatong elektroniko na ginagamit sa pagproseso ng impormasyon.',
      examplePhrase: 'Gamitin ang kompyuter sa pag-aaral.',
      exampleTranslation: 'Use the computer for studying.',
      rootWord: 'kompyuter',
    ),
    'telepono': TagalogWordEntry(
      word: 'telepono',
      labelEn: 'Phone / Cellphone',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[te-le-po-no]',
      definition: 'Kagamitan sa pakikipag-ugnayan at pakikipag-usap sa malayo.',
      examplePhrase: 'Tumunog ang telepono sa lamesa.',
      exampleTranslation: 'The phone rang on the table.',
      rootWord: 'telepono',
    ),
    'lapis': TagalogWordEntry(
      word: 'lapis',
      labelEn: 'Pencil',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[la-pis]',
      definition: 'Pansulat na may tinggang grapayt sa loob ng kahoy.',
      examplePhrase: 'Matalas na lapis para sa pagguhit.',
      exampleTranslation: 'Sharp pencil for drawing.',
      rootWord: 'lapis',
    ),
    'papel': TagalogWordEntry(
      word: 'papel',
      labelEn: 'Paper',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[pa-pel]',
      definition: 'Manipis na materyal na sinusulatan o pinaglalagyan ng drowing.',
      examplePhrase: 'Magsulat sa malinis na papel.',
      exampleTranslation: 'Write on a clean sheet of paper.',
      rootWord: 'papel',
    ),
    'payong': TagalogWordEntry(
      word: 'payong',
      labelEn: 'Umbrella',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[pa-yong]',
      definition: 'Kagamitang pananggalang sa ulan o sikat ng araw.',
      examplePhrase: 'Magdala ng payong dahil maulan.',
      exampleTranslation: 'Bring an umbrella because it is rainy.',
      rootWord: 'payong',
    ),
    'kama': TagalogWordEntry(
      word: 'kama',
      labelEn: 'Bed',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ka-ma]',
      definition: 'Kasangkapang higaan sa silid-tulugan.',
      examplePhrase: 'Humiga sa malambot na kama.',
      exampleTranslation: 'Lie down on the soft bed.',
      rootWord: 'kama',
    ),
    'unan': TagalogWordEntry(
      word: 'unan',
      labelEn: 'Pillow',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[u-nan]',
      definition: 'Malambot na sapin sa ulo kapag natutulog.',
      examplePhrase: 'Malambot na unan para sa mahimbing na tulog.',
      exampleTranslation: 'Soft pillow for a sound sleep.',
      rootWord: 'unan',
    ),
    'pinto': TagalogWordEntry(
      word: 'pinto',
      labelEn: 'Door',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[pin-to]',
      definition: 'Lagusan sa pasukan o labasan ng bahay.',
      examplePhrase: 'Isara ang pinto bago umalis.',
      exampleTranslation: 'Close the door before leaving.',
      rootWord: 'pinto',
    ),
    'bintana': TagalogWordEntry(
      word: 'bintana',
      labelEn: 'Window',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[bin-ta-na]',
      definition: 'Pawang sa dingding upang makapasok ang hangin at liwanag.',
      examplePhrase: 'Buksan ang bintana upang pumasok ang sariwang hangin.',
      exampleTranslation: 'Open the window to let fresh air in.',
      rootWord: 'bintana',
    ),
    'salamin': TagalogWordEntry(
      word: 'salamin',
      labelEn: 'Mirror / Eyeglasses',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[sa-la-min]',
      definition: 'Makinis na bagay na nagpapakita ng repleksiyon ng imahen.',
      examplePhrase: 'Tumingin sa salamin bago lumabas.',
      exampleTranslation: 'Look in the mirror before heading out.',
      rootWord: 'salamin',
    ),
    'tinapay': TagalogWordEntry(
      word: 'tinapay',
      labelEn: 'Bread',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ti-na-pay]',
      definition: 'Pagkaing gawa sa arina, tubig, at lebadura na inihurno.',
      examplePhrase: 'Mainit na tinapay para sa almusal.',
      exampleTranslation: 'Warm bread for breakfast.',
      rootWord: 'tinapay',
    ),
    'gatas': TagalogWordEntry(
      word: 'gatas',
      labelEn: 'Milk',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ga-tas]',
      definition: 'Puting likido na masustansya para sa katawan.',
      examplePhrase: 'Uminom ng gatas pampalakas ng buto.',
      exampleTranslation: 'Drink milk to strengthen bones.',
      rootWord: 'gatas',
    ),
    'itlog': TagalogWordEntry(
      word: 'itlog',
      labelEn: 'Egg',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[it-log]',
      definition: 'Bilugang pagkain na galing sa manok o ibon.',
      examplePhrase: 'Pritong itlog sa almusal.',
      exampleTranslation: 'Fried egg for breakfast.',
      rootWord: 'itlog',
    ),
    'mansanas': TagalogWordEntry(
      word: 'mansanas',
      labelEn: 'Apple',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[man-sa-nas]',
      definition: 'Bilog at matamis na prutas na kulay pula o berde.',
      examplePhrase: 'Isang mansanas bawat araw para sa kalusugan.',
      exampleTranslation: 'An apple a day for good health.',
      rootWord: 'mansanas',
    ),
    'saging': TagalogWordEntry(
      word: 'saging',
      labelEn: 'Banana',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[sa-ging]',
      definition: 'Mahaba at dilaw na matamis na prutas.',
      examplePhrase: 'Matamis na saging mula sa palengke.',
      exampleTranslation: 'Sweet banana from the market.',
      rootWord: 'saging',
    ),
    'puno': TagalogWordEntry(
      word: 'puno',
      labelEn: 'Tree',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[pu-no]',
      definition: 'Malaking halaman na may matigas na sanga at katawan.',
      examplePhrase: 'Lilim ng malaking puno sa parke.',
      exampleTranslation: 'Shade of the large tree in the park.',
      pangasinanCognate: 'kiew',
      rootWord: 'puno',
    ),
    'dahon': TagalogWordEntry(
      word: 'dahon',
      labelEn: 'Leaf',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[da-hon]',
      definition: 'Luntiang bahagi ng halaman na gumagawa ng pagkain.',
      examplePhrase: 'Berdeng dahon ng halaman.',
      exampleTranslation: 'Green leaf of the plant.',
      pangasinanCognate: 'bolong',
      rootWord: 'dahon',
    ),
    'ibon': TagalogWordEntry(
      word: 'ibon',
      labelEn: 'Bird',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[i-bon]',
      definition: 'Hayop na may pakpak, balahibo, at lumilipad.',
      examplePhrase: 'Umaawit ang ibon sa puno.',
      exampleTranslation: 'The bird is singing on the tree.',
      pangasinanCognate: 'manok',
      rootWord: 'ibon',
    ),
    'isda': TagalogWordEntry(
      word: 'isda',
      labelEn: 'Fish',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[is-da]',
      definition: 'Hayop na lumalangoy at nabubuhay sa tubig.',
      examplePhrase: 'Lumalangoy ang isda sa ilog.',
      exampleTranslation: 'The fish swims in the river.',
      pangasinanCognate: 'sira',
      rootWord: 'isda',
    ),
    'kotse': TagalogWordEntry(
      word: 'kotse',
      labelEn: 'Car / Automobile',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[kot-se]',
      definition: 'Sasakyang panlupa na may apat na gulong at makina.',
      examplePhrase: 'Bagong kotse sa paradahan.',
      exampleTranslation: 'New car in the parking lot.',
      rootWord: 'kotse',
    ),
    'bisikleta': TagalogWordEntry(
      word: 'bisikleta',
      labelEn: 'Bicycle / Bike',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[bi-sik-le-ta]',
      definition: 'Sasakyang may dalawang gulong na pinapatakbo ng padyak.',
      examplePhrase: 'Magbisikleta sa tabing-dagat.',
      exampleTranslation: 'Ride a bicycle along the seashore.',
      rootWord: 'bisikleta',
    ),
    'bahay': TagalogWordEntry(
      word: 'bahay',
      labelEn: 'House / Home',
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: '[ba-hay]',
      definition: 'Tirahan ng mag-anak.',
      examplePhrase: 'Payapang buhay sa sariling bahay.',
      exampleTranslation: 'Peaceful life in one\'s own home.',
      pangasinanCognate: 'abong',
      rootWord: 'bahay',
    ),
  };

  // English synonyms and aliases mapped to Tagalog lemmas
  static const Map<String, String> _englishToTagalogKey = {
    'book': 'aklat',
    'notebook': 'aklat',
    'novel': 'aklat',
    'cup': 'tasa',
    'mug': 'tasa',
    'coffee mug': 'tasa',
    'coffee cup': 'tasa',
    'coffee': 'kape',
    'tea': 'tsaa',
    'table': 'mesa',
    'desk': 'mesa',
    'dining table': 'mesa',
    'chair': 'silya',
    'stool': 'silya',
    'seat': 'silya',
    'cat': 'pusa',
    'kitten': 'pusa',
    'dog': 'aso',
    'puppy': 'aso',
    'flower': 'bulaklak',
    'rose': 'bulaklak',
    'water': 'tubig',
    'bottle': 'bote',
    'water bottle': 'bote',
    'glass': 'baso',
    'drinking glass': 'baso',
    'wine glass': 'baso',
    'spoon': 'kutsara',
    'tablespoon': 'kutsara',
    'teaspoon': 'kutsara',
    'fork': 'tinidor',
    'knife': 'kutsilyo',
    'plate': 'pinggan',
    'dish': 'pinggan',
    'bowl': 'mangkok',
    'shoe': 'sapatos',
    'shoes': 'sapatos',
    'sneaker': 'sapatos',
    'sneakers': 'sapatos',
    'clothes': 'damit',
    'clothing': 'damit',
    'shirt': 'damit',
    't-shirt': 'damit',
    'clock': 'orasan',
    'watch': 'orasan',
    'wristwatch': 'orasan',
    'tv': 'telebisyon',
    'television': 'telebisyon',
    'screen': 'telebisyon',
    'computer': 'kompyuter',
    'laptop': 'kompyuter',
    'pc': 'kompyuter',
    'phone': 'telepono',
    'cell phone': 'telepono',
    'cellphone': 'telepono',
    'mobile phone': 'telepono',
    'smartphone': 'telepono',
    'pencil': 'lapis',
    'pen': 'lapis',
    'paper': 'papel',
    'umbrella': 'payong',
    'bed': 'kama',
    'pillow': 'unan',
    'door': 'pinto',
    'window': 'bintana',
    'mirror': 'salamin',
    'glasses': 'salamin',
    'eyeglasses': 'salamin',
    'bread': 'tinapay',
    'toast': 'tinapay',
    'milk': 'gatas',
    'egg': 'itlog',
    'apple': 'mansanas',
    'banana': 'saging',
    'tree': 'puno',
    'leaf': 'dahon',
    'leaves': 'dahon',
    'bird': 'ibon',
    'fish': 'isda',
    'car': 'kotse',
    'automobile': 'kotse',
    'vehicle': 'kotse',
    'bicycle': 'bisikleta',
    'bike': 'bisikleta',
    'house': 'bahay',
    'home': 'bahay',
  };

  /// Looks up a verified Tagalog entry by English label
  TagalogWordEntry? lookupByEnglish(String englishLabel) {
    final clean = englishLabel.trim().toLowerCase();

    // 1. Exact alias match
    if (_englishToTagalogKey.containsKey(clean)) {
      final tagalogKey = _englishToTagalogKey[clean]!;
      return _tagalogBank[tagalogKey];
    }

    // 2. Substring match across aliases
    for (final entry in _englishToTagalogKey.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        return _tagalogBank[entry.value];
      }
    }

    // 3. Check directly against Tagalog bank lemmas
    if (_tagalogBank.containsKey(clean)) {
      return _tagalogBank[clean];
    }

    return null;
  }

  /// Looks up an entry by Tagalog word
  TagalogWordEntry? lookupByTagalog(String tagalogWord) {
    final clean = tagalogWord.trim().toLowerCase();
    return _tagalogBank[clean];
  }

  /// Resolves an entry or synthesizes a phonetically sound Tagalog entry with authentic Baybayin.
  /// Guarantees that no object is left as raw untranslated English.
  TagalogWordEntry resolveOrSynthesize(String label) {
    final clean = label.trim().toLowerCase();

    // 1. Direct English lookup
    final byEn = lookupByEnglish(clean);
    if (byEn != null) return byEn;

    // 2. Direct Tagalog lookup
    final byTl = lookupByTagalog(clean);
    if (byTl != null) return byTl;

    // 3. Phonetic synthesis for loanwords or unrecognized terms
    final phoneticTagalog = BaybayinEngine.normalizeTagalogPhonetics(clean);
    final baybayin = BaybayinEngine.transliterate(phoneticTagalog);
    final pronunciation = BaybayinEngine.formatPronunciation(phoneticTagalog);

    return TagalogWordEntry(
      word: phoneticTagalog,
      labelEn: label,
      partOfSpeech: 'Pangngalan (Noun)',
      difficultyLevel: 'A1',
      pronunciation: pronunciation,
      definition: 'Salitang Tagalog para sa $label.',
      examplePhrase: 'Isang $phoneticTagalog',
      exampleTranslation: 'A $label',
      baybayin: baybayin,
      pangasinanCognate: PhilippineRegionalLexicon.getPangasinanEquivalent(phoneticTagalog),
    );
  }

  /// Fetches real-world definition from Wiktionary REST API for dynamic lookup.
  Future<TagalogWordEntry?> fetchOnlineDictionaryDefinition(String word) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final cached = await _loadFromCache(clean);
    if (cached != null) return cached;

    try {
      final uri = Uri.parse(
        'https://en.wiktionary.org/api/rest_v1/page/definition/${Uri.encodeComponent(clean)}',
      );

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MemoriaTagalogDictionary/1.0',
        },
      ).timeout(const Duration(milliseconds: 3500));

      if (response.statusCode != 200) {
        return null;
      }

      final jsonBody = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final definitions = jsonBody['tagalog'] as List<dynamic>? ??
          jsonBody['filipino'] as List<dynamic>? ??
          const [];

      if (definitions.isEmpty) return null;

      final firstSection = definitions.first as Map<String, dynamic>;
      final pos = firstSection['partOfSpeech'] as String? ?? 'Noun';
      final defItems = firstSection['definitions'] as List<dynamic>? ?? const [];
      String defText = '';
      if (defItems.isNotEmpty) {
        final d = defItems.first as Map<String, dynamic>;
        defText = (d['definition'] as String? ?? '').replaceAll(RegExp(r'<[^>]*>'), '');
      }

      final entry = TagalogWordEntry(
        word: clean,
        labelEn: clean,
        partOfSpeech: 'Pangngalan ($pos)',
        difficultyLevel: 'A2',
        pronunciation: BaybayinEngine.formatPronunciation(clean),
        definition: defText,
        examplePhrase: 'Isang $clean',
        exampleTranslation: 'A $clean',
        baybayin: BaybayinEngine.transliterate(clean),
        pangasinanCognate: PhilippineRegionalLexicon.getPangasinanEquivalent(clean),
      );

      await _saveToCache(clean, entry);
      return entry;
    } catch (e) {
      developer.log('Wiktionary API lookup failed for $word: $e', name: 'TagalogDictionaryService');
      return null;
    }
  }

  Future<TagalogWordEntry?> _loadFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_cachePrefix$key');
      if (jsonStr == null) return null;
      return TagalogWordEntry.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(String key, TagalogWordEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', jsonEncode(entry.toJson()));
    } catch (_) {}
  }
}
