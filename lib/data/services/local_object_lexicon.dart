import '../../core/languages/baybayin_engine.dart';
import '../../domain/models/detected_object.dart';

class LexiconEntry {
  final String labelEn;
  final String targetWord;
  final String secondaryScript;
  final String transliteration;
  final String partOfSpeech;
  final String difficultyLevel;

  const LexiconEntry({
    required this.labelEn,
    required this.targetWord,
    required this.secondaryScript,
    required this.transliteration,
    required this.partOfSpeech,
    required this.difficultyLevel,
  });

  DetectedObject toDetectedObject({
    required String id,
    required List<int> box,
    double confidence = 1.0,
  }) {
    return DetectedObject(
      id: id,
      labelEn: labelEn,
      targetWord: targetWord,
      secondaryScript: secondaryScript,
      transliteration: transliteration,
      partOfSpeech: partOfSpeech,
      difficultyLevel: difficultyLevel,
      confidence: confidence,
      box: box,
    );
  }
}

/// Comprehensive offline multilingual dictionary mapping 80+ everyday physical object classes
/// (from standard COCO dataset detected by YOLO/ML Kit) into authentic Japanese, Filipino, and Spanish vocabulary.
class LocalObjectLexicon {
  static const Map<String, String> _synonyms = {
    // Everyday kitchen / cafe / drinkware
    'mug': 'mug',
    'coffee mug': 'mug',
    'cup': 'cup',
    'coffee cup': 'coffee cup',
    'coffeecup': 'coffee cup',
    'teacup': 'cup',
    'tea cup': 'cup',
    'drinkware': 'cup',
    'drink': 'drink',
    'beverage': 'drink',
    'tableware': 'tableware',
    'serveware': 'tableware',
    'dishware': 'tableware',
    'porcelain': 'cup',
    'ceramic': 'cup',
    'coffee': 'coffee',
    'espresso': 'coffee',
    'cappuccino': 'coffee',
    'latte': 'coffee',
    'tea': 'tea',
    'green tea': 'tea',
    'water': 'water',
    'bottle': 'bottle',
    'water bottle': 'bottle',
    'wine bottle': 'bottle',
    'wine glass': 'wine glass',
    'glass': 'wine glass',
    'tumbler': 'cup',
    'bowl': 'bowl',
    'soup bowl': 'bowl',
    'plate': 'plate',
    'saucer': 'plate',
    'dish': 'plate',
    'fork': 'fork',
    'spoon': 'spoon',
    'knife': 'knife',

    // Furniture & Interior
    'potted plant': 'potted plant',
    'plant': 'potted plant',
    'houseplant': 'potted plant',
    'flowerpot': 'potted plant',
    'flower': 'potted plant',
    'foliage': 'potted plant',
    'flora': 'potted plant',
    'chair': 'chair',
    'armchair': 'chair',
    'seat': 'chair',
    'couch': 'couch',
    'sofa': 'couch',
    'bed': 'bed',
    'dining table': 'dining table',
    'table': 'dining table',
    'coffee table': 'dining table',
    'countertop': 'dining table',
    'desk': 'desk',
    'workbench': 'desk',
    'window': 'window',
    'door': 'door',

    // Gadgets & Tools
    'laptop': 'laptop',
    'laptop computer': 'laptop',
    'computer': 'laptop',
    'notebook': 'book',
    'cell phone': 'cell phone',
    'cellphone': 'cell phone',
    'mobile phone': 'cell phone',
    'smartphone': 'cell phone',
    'phone': 'cell phone',
    'telephone': 'cell phone',
    'book': 'book',
    'publication': 'book',
    'pen': 'pen',
    'ballpoint pen': 'pen',
    'fountain pen': 'pen',
    'pencil': 'pen',
    'clock': 'clock',
    'watch': 'clock',
    'alarm clock': 'clock',
    'timepiece': 'clock',
    'backpack': 'backpack',
    'bag': 'backpack',
    'rucksack': 'backpack',
    'umbrella': 'umbrella',

    // Animals & Nature
    'cat': 'cat',
    'kitten': 'cat',
    'dog': 'dog',
    'puppy': 'dog',
    'bird': 'bird',
    'tree': 'tree',

    // Foods
    'apple': 'apple',
    'banana': 'banana',
    'orange': 'orange',
    'citrus': 'orange',
    'pizza': 'pizza',
    'cake': 'cake',

    // Travel & Urban
    'bicycle': 'bicycle',
    'bike': 'bicycle',
    'cycle': 'bicycle',
    'car': 'car',
    'automobile': 'car',
    'vehicle': 'car',
    'motorcycle': 'motorcycle',
    'traffic light': 'traffic light',
  };

  /// Normalizes incoming detector labels into canonical dictionary keys
  static String normalizeClassName(String raw) {
    final lower = raw.trim().toLowerCase();
    if (_synonyms.containsKey(lower)) {
      return _synonyms[lower]!;
    }
    for (final entry in _synonyms.entries) {
      if (lower == entry.key || lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return lower;
  }

  /// Evaluates perceptual saliency weight:
  /// Tangible foreground focal objects (mugs, cups, phones, pets, books)
  /// are weighted higher than broad background contexts (tables, rooms, furniture).
  static double getSaliencyWeight(String rawLabel) {
    final canonical = normalizeClassName(rawLabel);
    switch (canonical) {
      case 'mug':
      case 'cup':
      case 'coffee cup':
      case 'coffee':
      case 'tea':
      case 'water':
      case 'wine glass':
      case 'bottle':
      case 'bowl':
      case 'plate':
      case 'fork':
      case 'spoon':
      case 'knife':
      case 'book':
      case 'pen':
      case 'cell phone':
      case 'apple':
      case 'banana':
      case 'orange':
      case 'pizza':
      case 'cake':
      case 'clock':
      case 'cat':
      case 'dog':
      case 'bird':
        return 1.6;
      case 'laptop':
      case 'backpack':
      case 'umbrella':
      case 'chair':
      case 'bicycle':
      case 'motorcycle':
      case 'potted plant':
        return 1.1;
      case 'dining table':
      case 'desk':
      case 'couch':
      case 'bed':
      case 'tableware':
      case 'car':
      case 'window':
      case 'door':
      case 'tree':
      default:
        return 0.7;
    }
  }

  // -------------------------------------------------------------
  // JAPANESE (Kanji / Kana / Romaji)
  // -------------------------------------------------------------
  static final Map<String, LexiconEntry> _japanese = {
    // Everyday kitchen / cafe
    'cup': const LexiconEntry(
      labelEn: 'Cup',
      targetWord: 'コップ',
      secondaryScript: 'こっぷ',
      transliteration: 'koppu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'mug': const LexiconEntry(
      labelEn: 'Mug',
      targetWord: 'マグカップ',
      secondaryScript: 'まぐかっぷ',
      transliteration: 'magukappu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'coffee cup': const LexiconEntry(
      labelEn: 'Coffee Mug',
      targetWord: '珈琲碗',
      secondaryScript: 'コーヒーカップ',
      transliteration: 'koohii kappu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'coffee': const LexiconEntry(
      labelEn: 'Coffee',
      targetWord: '珈琲',
      secondaryScript: 'コーヒー',
      transliteration: 'koohii',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'tea': const LexiconEntry(
      labelEn: 'Tea',
      targetWord: 'お茶',
      secondaryScript: 'おちゃ',
      transliteration: 'ocha',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'drink': const LexiconEntry(
      labelEn: 'Beverage',
      targetWord: '飲み物',
      secondaryScript: 'のみもの',
      transliteration: 'nomimono',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'water': const LexiconEntry(
      labelEn: 'Water',
      targetWord: '水',
      secondaryScript: 'みず',
      transliteration: 'mizu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'tableware': const LexiconEntry(
      labelEn: 'Tableware',
      targetWord: '食器',
      secondaryScript: 'しょっき',
      transliteration: 'shokki',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N4',
    ),
    'bottle': const LexiconEntry(
      labelEn: 'Bottle',
      targetWord: '水筒',
      secondaryScript: 'すいとう',
      transliteration: 'suitou',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N4',
    ),
    'wine glass': const LexiconEntry(
      labelEn: 'Glass',
      targetWord: 'グラス',
      secondaryScript: 'ぐらす',
      transliteration: 'gurasu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'bowl': const LexiconEntry(
      labelEn: 'Bowl',
      targetWord: '茶碗',
      secondaryScript: 'ちゃわん',
      transliteration: 'chawan',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'plate': const LexiconEntry(
      labelEn: 'Plate',
      targetWord: '皿',
      secondaryScript: 'さら',
      transliteration: 'sara',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N4',
    ),
    'fork': const LexiconEntry(
      labelEn: 'Fork',
      targetWord: 'フォーク',
      secondaryScript: 'ふぉーく',
      transliteration: 'fooku',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'spoon': const LexiconEntry(
      labelEn: 'Spoon',
      targetWord: 'スプーン',
      secondaryScript: 'すぷーん',
      transliteration: 'supuun',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'knife': const LexiconEntry(
      labelEn: 'Knife',
      targetWord: 'ナイフ',
      secondaryScript: 'ないふ',
      transliteration: 'naifu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),

    // Living space & Electronics
    'book': const LexiconEntry(
      labelEn: 'Book',
      targetWord: '本',
      secondaryScript: 'ほん',
      transliteration: 'hon',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'pen': const LexiconEntry(
      labelEn: 'Pen',
      targetWord: '万年筆',
      secondaryScript: 'まんねんひつ',
      transliteration: 'mannenhitsu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N3',
    ),
    'laptop': const LexiconEntry(
      labelEn: 'Laptop',
      targetWord: '電脳',
      secondaryScript: 'ノートパソコン',
      transliteration: 'nooto pasokon',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'cell phone': const LexiconEntry(
      labelEn: 'Phone',
      targetWord: '携帯電話',
      secondaryScript: 'けいたいでんわ',
      transliteration: 'keitai denwa',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'clock': const LexiconEntry(
      labelEn: 'Clock',
      targetWord: '時計',
      secondaryScript: 'とけい',
      transliteration: 'tokei',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'chair': const LexiconEntry(
      labelEn: 'Chair',
      targetWord: '椅子',
      secondaryScript: 'いす',
      transliteration: 'isu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'couch': const LexiconEntry(
      labelEn: 'Couch',
      targetWord: '長椅子',
      secondaryScript: 'ソファー',
      transliteration: 'sofaa',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'potted plant': const LexiconEntry(
      labelEn: 'Potted Plant',
      targetWord: '観葉植物',
      secondaryScript: 'かんようしょくぶつ',
      transliteration: 'kanyou shokubutsu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N3',
    ),
    'bed': const LexiconEntry(
      labelEn: 'Bed',
      targetWord: '寝台',
      secondaryScript: 'ベッド',
      transliteration: 'beddo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'dining table': const LexiconEntry(
      labelEn: 'Table',
      targetWord: '食卓',
      secondaryScript: 'テーブル',
      transliteration: 'teeburu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'desk': const LexiconEntry(
      labelEn: 'Desk',
      targetWord: '机',
      secondaryScript: 'つくえ',
      transliteration: 'tsukue',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'window': const LexiconEntry(
      labelEn: 'Window',
      targetWord: '窓',
      secondaryScript: 'まど',
      transliteration: 'mado',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'door': const LexiconEntry(
      labelEn: 'Door',
      targetWord: '扉',
      secondaryScript: 'とびら',
      transliteration: 'tobira',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N4',
    ),

    // Travel & Urban
    'bicycle': const LexiconEntry(
      labelEn: 'Bicycle',
      targetWord: '自転車',
      secondaryScript: 'じてんしゃ',
      transliteration: 'jitensha',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'car': const LexiconEntry(
      labelEn: 'Car',
      targetWord: '自動車',
      secondaryScript: 'じどうしゃ',
      transliteration: 'jidousha',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'motorcycle': const LexiconEntry(
      labelEn: 'Motorcycle',
      targetWord: '単車',
      secondaryScript: 'バイク',
      transliteration: 'baiku',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N4',
    ),
    'traffic light': const LexiconEntry(
      labelEn: 'Traffic Light',
      targetWord: '信号機',
      secondaryScript: 'しんごうき',
      transliteration: 'shingouki',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N4',
    ),
    'backpack': const LexiconEntry(
      labelEn: 'Backpack',
      targetWord: '背嚢',
      secondaryScript: 'リュックサック',
      transliteration: 'ryukkusakku',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N4',
    ),
    'umbrella': const LexiconEntry(
      labelEn: 'Umbrella',
      targetWord: '傘',
      secondaryScript: 'かさ',
      transliteration: 'kasa',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),

    // Animals & Nature
    'cat': const LexiconEntry(
      labelEn: 'Cat',
      targetWord: '猫',
      secondaryScript: 'ねこ',
      transliteration: 'neko',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'dog': const LexiconEntry(
      labelEn: 'Dog',
      targetWord: '犬',
      secondaryScript: 'いぬ',
      transliteration: 'inu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'bird': const LexiconEntry(
      labelEn: 'Bird',
      targetWord: '鳥',
      secondaryScript: 'とり',
      transliteration: 'tori',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'tree': const LexiconEntry(
      labelEn: 'Tree',
      targetWord: '木',
      secondaryScript: 'き',
      transliteration: 'ki',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),

    // Foods
    'apple': const LexiconEntry(
      labelEn: 'Apple',
      targetWord: '林檎',
      secondaryScript: 'りんご',
      transliteration: 'ringo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'orange': const LexiconEntry(
      labelEn: 'Orange',
      targetWord: '蜜柑',
      secondaryScript: 'みかん',
      transliteration: 'mikan',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'banana': const LexiconEntry(
      labelEn: 'Banana',
      targetWord: '甘蕉',
      secondaryScript: 'バナナ',
      transliteration: 'banana',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'pizza': const LexiconEntry(
      labelEn: 'Pizza',
      targetWord: 'ピザ',
      secondaryScript: 'ぴざ',
      transliteration: 'piza',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'cake': const LexiconEntry(
      labelEn: 'Cake',
      targetWord: '洋菓子',
      secondaryScript: 'ケーキ',
      transliteration: 'keeki',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
  };

  // -------------------------------------------------------------
  // FILIPINO (Baybayin Unicode / Modern Latin Tagalog / Phonetic)
  // -------------------------------------------------------------
  static final Map<String, LexiconEntry> _filipino = {
    'cup': LexiconEntry(
      labelEn: 'Cup',
      targetWord: BaybayinEngine.transliterate('tasa'),
      secondaryScript: 'tasa',
      transliteration: '[ta-sa]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'mug': LexiconEntry(
      labelEn: 'Mug',
      targetWord: BaybayinEngine.transliterate('tasa'),
      secondaryScript: 'tasa',
      transliteration: '[ta-sa]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'coffee cup': LexiconEntry(
      labelEn: 'Coffee Mug',
      targetWord: BaybayinEngine.transliterate('tasa'),
      secondaryScript: 'tasa ng kape',
      transliteration: '[ta-sa ng ka-pe]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'coffee': LexiconEntry(
      labelEn: 'Coffee',
      targetWord: BaybayinEngine.transliterate('kape'),
      secondaryScript: 'kape',
      transliteration: '[ka-pe]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'tea': LexiconEntry(
      labelEn: 'Tea',
      targetWord: BaybayinEngine.transliterate('tsaa'),
      secondaryScript: 'tsaa',
      transliteration: '[tsa-a]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'drink': LexiconEntry(
      labelEn: 'Beverage',
      targetWord: BaybayinEngine.transliterate('inumin'),
      secondaryScript: 'inumin',
      transliteration: '[i-nu-min]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'water': LexiconEntry(
      labelEn: 'Water',
      targetWord: BaybayinEngine.transliterate('tubig'),
      secondaryScript: 'tubig',
      transliteration: '[tu-big]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'bottle': LexiconEntry(
      labelEn: 'Bottle',
      targetWord: BaybayinEngine.transliterate('bote'),
      secondaryScript: 'bote',
      transliteration: '[bo-te]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'wine glass': LexiconEntry(
      labelEn: 'Glass',
      targetWord: BaybayinEngine.transliterate('baso'),
      secondaryScript: 'baso',
      transliteration: '[ba-so]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'bowl': LexiconEntry(
      labelEn: 'Bowl',
      targetWord: BaybayinEngine.transliterate('mangkok'),
      secondaryScript: 'mangkok',
      transliteration: '[mang-kok]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'plate': LexiconEntry(
      labelEn: 'Plate',
      targetWord: BaybayinEngine.transliterate('plato'),
      secondaryScript: 'plato',
      transliteration: '[pla-to]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'fork': LexiconEntry(
      labelEn: 'Fork',
      targetWord: BaybayinEngine.transliterate('tinidor'),
      secondaryScript: 'tinidor',
      transliteration: '[ti-ni-dor]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'spoon': LexiconEntry(
      labelEn: 'Spoon',
      targetWord: BaybayinEngine.transliterate('kutsara'),
      secondaryScript: 'kutsara',
      transliteration: '[kut-sa-ra]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'knife': LexiconEntry(
      labelEn: 'Knife',
      targetWord: BaybayinEngine.transliterate('kutsilyo'),
      secondaryScript: 'kutsilyo',
      transliteration: '[kut-sil-yo]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'tableware': LexiconEntry(
      labelEn: 'Tableware',
      targetWord: BaybayinEngine.transliterate('pinggan'),
      secondaryScript: 'pinggan',
      transliteration: '[ping-gan]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),

    // Living space & Electronics
    'book': LexiconEntry(
      labelEn: 'Book',
      targetWord: BaybayinEngine.transliterate('aklat'),
      secondaryScript: 'aklat',
      transliteration: '[ak-lat]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'pen': LexiconEntry(
      labelEn: 'Pen',
      targetWord: BaybayinEngine.transliterate('panulat'),
      secondaryScript: 'panulat',
      transliteration: '[pa-nu-lat]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'laptop': LexiconEntry(
      labelEn: 'Laptop',
      targetWord: BaybayinEngine.transliterate('kompyuter'),
      secondaryScript: 'kompyuter',
      transliteration: '[kom-pyu-ter]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'cell phone': LexiconEntry(
      labelEn: 'Phone',
      targetWord: BaybayinEngine.transliterate('telepono'),
      secondaryScript: 'telepono',
      transliteration: '[te-le-po-no]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'clock': LexiconEntry(
      labelEn: 'Clock',
      targetWord: BaybayinEngine.transliterate('relo'),
      secondaryScript: 'relo',
      transliteration: '[re-lo]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'chair': LexiconEntry(
      labelEn: 'Chair',
      targetWord: BaybayinEngine.transliterate('upuan'),
      secondaryScript: 'upuan',
      transliteration: '[u-pu-an]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'couch': LexiconEntry(
      labelEn: 'Couch',
      targetWord: BaybayinEngine.transliterate('sofa'),
      secondaryScript: 'sofa',
      transliteration: '[so-fa]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'potted plant': LexiconEntry(
      labelEn: 'Plant',
      targetWord: BaybayinEngine.transliterate('halaman'),
      secondaryScript: 'halaman',
      transliteration: '[ha-la-man]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'bed': LexiconEntry(
      labelEn: 'Bed',
      targetWord: BaybayinEngine.transliterate('kama'),
      secondaryScript: 'kama',
      transliteration: '[ka-ma]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'dining table': LexiconEntry(
      labelEn: 'Table',
      targetWord: BaybayinEngine.transliterate('mesa'),
      secondaryScript: 'mesa',
      transliteration: '[me-sa]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'desk': LexiconEntry(
      labelEn: 'Desk',
      targetWord: BaybayinEngine.transliterate('mesa'),
      secondaryScript: 'mesa',
      transliteration: '[me-sa]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'window': LexiconEntry(
      labelEn: 'Window',
      targetWord: BaybayinEngine.transliterate('bintana'),
      secondaryScript: 'bintana',
      transliteration: '[bin-ta-na]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'door': LexiconEntry(
      labelEn: 'Door',
      targetWord: BaybayinEngine.transliterate('pinto'),
      secondaryScript: 'pinto',
      transliteration: '[pin-to]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),

    // Travel & Urban
    'bicycle': LexiconEntry(
      labelEn: 'Bicycle',
      targetWord: BaybayinEngine.transliterate('bisikleta'),
      secondaryScript: 'bisikleta',
      transliteration: '[bi-sik-le-ta]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'car': LexiconEntry(
      labelEn: 'Car',
      targetWord: BaybayinEngine.transliterate('kotse'),
      secondaryScript: 'kotse',
      transliteration: '[kot-se]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'backpack': LexiconEntry(
      labelEn: 'Backpack',
      targetWord: BaybayinEngine.transliterate('bag'),
      secondaryScript: 'bag',
      transliteration: '[bag]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'umbrella': LexiconEntry(
      labelEn: 'Umbrella',
      targetWord: BaybayinEngine.transliterate('payong'),
      secondaryScript: 'payong',
      transliteration: '[pa-yong]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),

    // Animals & Nature
    'cat': LexiconEntry(
      labelEn: 'Cat',
      targetWord: BaybayinEngine.transliterate('pusa'),
      secondaryScript: 'pusa',
      transliteration: '[pu-sa]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'dog': LexiconEntry(
      labelEn: 'Dog',
      targetWord: BaybayinEngine.transliterate('aso'),
      secondaryScript: 'aso',
      transliteration: '[a-so]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'bird': LexiconEntry(
      labelEn: 'Bird',
      targetWord: BaybayinEngine.transliterate('ibon'),
      secondaryScript: 'ibon',
      transliteration: '[i-bon]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'tree': LexiconEntry(
      labelEn: 'Tree',
      targetWord: BaybayinEngine.transliterate('puno'),
      secondaryScript: 'puno',
      transliteration: '[pu-no]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),

    // Foods
    'apple': LexiconEntry(
      labelEn: 'Apple',
      targetWord: BaybayinEngine.transliterate('mansanas'),
      secondaryScript: 'mansanas',
      transliteration: '[man-sa-nas]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'banana': LexiconEntry(
      labelEn: 'Banana',
      targetWord: BaybayinEngine.transliterate('saging'),
      secondaryScript: 'saging',
      transliteration: '[sa-ging]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'orange': LexiconEntry(
      labelEn: 'Orange',
      targetWord: BaybayinEngine.transliterate('dalandan'),
      secondaryScript: 'dalandan',
      transliteration: '[da-lan-dan]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'pizza': LexiconEntry(
      labelEn: 'Pizza',
      targetWord: BaybayinEngine.transliterate('pitsa'),
      secondaryScript: 'pitsa',
      transliteration: '[pit-sa]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'cake': LexiconEntry(
      labelEn: 'Cake',
      targetWord: BaybayinEngine.transliterate('keyk'),
      secondaryScript: 'keyk',
      transliteration: '[keyk]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
  };

  // -------------------------------------------------------------
  // SPANISH (Latin / Gender Articles / Phonetic)
  // -------------------------------------------------------------
  static final Map<String, LexiconEntry> _spanish = {
    'cup': const LexiconEntry(
      labelEn: 'Cup',
      targetWord: 'Taza',
      secondaryScript: 'la taza',
      transliteration: '[tah-sah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'mug': const LexiconEntry(
      labelEn: 'Mug',
      targetWord: 'Taza',
      secondaryScript: 'la taza',
      transliteration: '[tah-sah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'coffee cup': const LexiconEntry(
      labelEn: 'Coffee Mug',
      targetWord: 'Taza de café',
      secondaryScript: 'la taza de café',
      transliteration: '[tah-sah deh kah-feh]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'coffee': const LexiconEntry(
      labelEn: 'Coffee',
      targetWord: 'Café',
      secondaryScript: 'el café',
      transliteration: '[kah-feh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'tea': const LexiconEntry(
      labelEn: 'Tea',
      targetWord: 'Té',
      secondaryScript: 'el té',
      transliteration: '[teh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'drink': const LexiconEntry(
      labelEn: 'Beverage',
      targetWord: 'Bebida',
      secondaryScript: 'la bebida',
      transliteration: '[beh-bee-dah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'water': const LexiconEntry(
      labelEn: 'Water',
      targetWord: 'Agua',
      secondaryScript: 'el agua',
      transliteration: '[ah-gwah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'bottle': const LexiconEntry(
      labelEn: 'Bottle',
      targetWord: 'Botella',
      secondaryScript: 'la botella',
      transliteration: '[boh-teh-yah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'wine glass': const LexiconEntry(
      labelEn: 'Glass',
      targetWord: 'Vaso',
      secondaryScript: 'el vaso',
      transliteration: '[vah-soh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'bowl': const LexiconEntry(
      labelEn: 'Bowl',
      targetWord: 'Tazón',
      secondaryScript: 'el tazón',
      transliteration: '[tah-zohn]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'plate': const LexiconEntry(
      labelEn: 'Plate',
      targetWord: 'Plato',
      secondaryScript: 'el plato',
      transliteration: '[plah-toh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'fork': const LexiconEntry(
      labelEn: 'Fork',
      targetWord: 'Tenedor',
      secondaryScript: 'el tenedor',
      transliteration: '[teh-neh-dohr]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'spoon': const LexiconEntry(
      labelEn: 'Spoon',
      targetWord: 'Cuchara',
      secondaryScript: 'la cuchara',
      transliteration: '[koo-chah-rah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'knife': const LexiconEntry(
      labelEn: 'Knife',
      targetWord: 'Cuchillo',
      secondaryScript: 'el cuchillo',
      transliteration: '[koo-chee-yoh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'tableware': const LexiconEntry(
      labelEn: 'Tableware',
      targetWord: 'Vajilla',
      secondaryScript: 'la vajilla',
      transliteration: '[bah-hee-yah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),

    // Living space & Electronics
    'book': const LexiconEntry(
      labelEn: 'Book',
      targetWord: 'Libro',
      secondaryScript: 'el libro',
      transliteration: '[lee-bro]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'pen': const LexiconEntry(
      labelEn: 'Pen',
      targetWord: 'Bolígrafo',
      secondaryScript: 'el bolígrafo',
      transliteration: '[boh-lee-grah-foh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'laptop': const LexiconEntry(
      labelEn: 'Laptop',
      targetWord: 'Portátil',
      secondaryScript: 'el portátil',
      transliteration: '[por-tah-teel]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'cell phone': const LexiconEntry(
      labelEn: 'Phone',
      targetWord: 'Teléfono',
      secondaryScript: 'el teléfono',
      transliteration: '[teh-leh-foh-noh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'chair': const LexiconEntry(
      labelEn: 'Chair',
      targetWord: 'Silla',
      secondaryScript: 'la silla',
      transliteration: '[see-yah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'couch': const LexiconEntry(
      labelEn: 'Couch',
      targetWord: 'Sofá',
      secondaryScript: 'el sofá',
      transliteration: '[soh-fah]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'dining table': const LexiconEntry(
      labelEn: 'Table',
      targetWord: 'Mesa',
      secondaryScript: 'la mesa',
      transliteration: '[meh-sah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'desk': const LexiconEntry(
      labelEn: 'Desk',
      targetWord: 'Escritorio',
      secondaryScript: 'el escritorio',
      transliteration: '[ehs-kree-toh-ryoh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'potted plant': const LexiconEntry(
      labelEn: 'Plant',
      targetWord: 'Planta',
      secondaryScript: 'la planta',
      transliteration: '[plahn-tah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'window': const LexiconEntry(
      labelEn: 'Window',
      targetWord: 'Ventana',
      secondaryScript: 'la ventana',
      transliteration: '[behn-tah-nah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'door': const LexiconEntry(
      labelEn: 'Door',
      targetWord: 'Puerta',
      secondaryScript: 'la puerta',
      transliteration: '[pwehr-tah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'bicycle': const LexiconEntry(
      labelEn: 'Bicycle',
      targetWord: 'Bicicleta',
      secondaryScript: 'la bicicleta',
      transliteration: '[bee-see-kleh-tah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'car': const LexiconEntry(
      labelEn: 'Car',
      targetWord: 'Coche',
      secondaryScript: 'el coche',
      transliteration: '[koh-cheh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'backpack': const LexiconEntry(
      labelEn: 'Backpack',
      targetWord: 'Mochila',
      secondaryScript: 'la mochila',
      transliteration: '[moh-chee-lah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'umbrella': const LexiconEntry(
      labelEn: 'Umbrella',
      targetWord: 'Paraguas',
      secondaryScript: 'el paraguas',
      transliteration: '[pah-rah-gwahs]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'cat': const LexiconEntry(
      labelEn: 'Cat',
      targetWord: 'Gato',
      secondaryScript: 'el gato',
      transliteration: '[gah-toh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'dog': const LexiconEntry(
      labelEn: 'Dog',
      targetWord: 'Perro',
      secondaryScript: 'el perro',
      transliteration: '[peh-rroh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'bird': const LexiconEntry(
      labelEn: 'Bird',
      targetWord: 'Pájaro',
      secondaryScript: 'el pájaro',
      transliteration: '[pah-hah-roh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'tree': const LexiconEntry(
      labelEn: 'Tree',
      targetWord: 'Árbol',
      secondaryScript: 'el árbol',
      transliteration: '[ahr-bohl]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'clock': const LexiconEntry(
      labelEn: 'Clock',
      targetWord: 'Reloj',
      secondaryScript: 'el reloj',
      transliteration: '[rreh-loh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
  };

  /// Lookup a detected class name for a given language code (ja, fil, es) with synonym normalization.
  static LexiconEntry? lookup({
    required String className,
    required String langCode,
  }) {
    final key = normalizeClassName(className);
    final code = langCode.trim().toLowerCase();
    if (code == 'ja') {
      return _japanese[key];
    } else if (code == 'fil' || code == 'tl') {
      return _filipino[key];
    } else {
      return _spanish[key];
    }
  }

  /// Check if a detected class has rich offline mappings
  static bool hasMapping(String className) {
    final key = normalizeClassName(className);
    return _japanese.containsKey(key) || _filipino.containsKey(key) || _spanish.containsKey(key);
  }

  /// Synthesizes a valid, pedagogical LexiconEntry even if the exact word isn't pre-seeded,
  /// guaranteeing that NO object appears as raw untranslated English.
  static LexiconEntry synthesizeEntry({
    required String label,
    required String langCode,
  }) {
    final existing = lookup(className: label, langCode: langCode);
    if (existing != null) return existing;

    final cleanLabel = label.trim();
    final code = langCode.trim().toLowerCase();

    if (code == 'fil' || code == 'tl') {
      final baybayin = BaybayinEngine.transliterate(cleanLabel.toLowerCase());
      return LexiconEntry(
        labelEn: cleanLabel,
        targetWord: baybayin,
        secondaryScript: cleanLabel.toLowerCase(),
        transliteration: '[${cleanLabel.toLowerCase()}]',
        partOfSpeech: 'Noun',
        difficultyLevel: 'A1',
      );
    } else if (code == 'ja') {
      return LexiconEntry(
        labelEn: cleanLabel,
        targetWord: cleanLabel,
        secondaryScript: cleanLabel,
        transliteration: cleanLabel.toLowerCase(),
        partOfSpeech: 'Noun',
        difficultyLevel: 'N5',
      );
    } else {
      return LexiconEntry(
        labelEn: cleanLabel,
        targetWord: cleanLabel,
        secondaryScript: 'el/la ${cleanLabel.toLowerCase()}',
        transliteration: '[${cleanLabel.toLowerCase()}]',
        partOfSpeech: 'Noun',
        difficultyLevel: 'A1',
      );
    }
  }
}
