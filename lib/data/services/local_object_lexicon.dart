import '../../core/languages/baybayin_engine.dart';
import '../../core/services/tagalog_dictionary_service.dart';
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
/// (from standard COCO dataset detected by on-device computer vision / ML Kit) into authentic Japanese, Filipino, and Spanish vocabulary.
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
    'trash can': 'trash can',
    'trashcan': 'trash can',
    'trash': 'trash can',
    'waste': 'trash can',
    'waste container': 'trash can',
    'waste container system': 'trash can',
    'wastebasket': 'trash can',
    'garbage': 'trash can',
    'garbage can': 'trash can',
    'dustbin': 'trash can',
    'rubbish': 'trash can',
    'rubbish bin': 'trash can',
    'litter bin': 'trash can',
    'wheelie bin': 'trash can',
    'recycling bin': 'trash can',
    'bin': 'trash can',
    'refuse': 'trash can',
    'dumpster': 'trash can',
    'bucket': 'bucket',
    'pail': 'bucket',

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

    // Foods & Dining
    'apple': 'apple',
    'banana': 'banana',
    'orange': 'orange',
    'citrus': 'orange',
    'pizza': 'pizza',
    'cake': 'cake',
    'food': 'food',
    'fast food': 'food',
    'meal': 'food',
    'cuisine': 'food',
    'dairy product': 'food',
    'chicken': 'chicken',
    'poultry': 'chicken',
    'fried chicken': 'chicken',
    'chicken meat': 'chicken',
    'ice cream': 'ice cream',
    'icecream': 'ice cream',
    'ice-cream': 'ice cream',
    'frozen dessert': 'ice cream',
    'gelato': 'ice cream',
    'sorbet': 'ice cream',
    'dessert': 'dessert',
    'sweets': 'dessert',
    'sweetness': 'dessert',
    'snack': 'snack',
    'candy': 'snack',
    'meat': 'meat',
    'beef': 'meat',
    'pork': 'meat',
    'rice': 'rice',
    'fried rice': 'rice',
    'noodle': 'noodles',
    'noodles': 'noodles',
    'ramen': 'noodles',
    'pasta': 'noodles',
    'spaghetti': 'noodles',
    'soup': 'soup',
    'broth': 'soup',
    'bread': 'bread',
    'toast': 'bread',
    'bun': 'bread',
    'sandwich': 'bread',
    'hamburger': 'burger',
    'burger': 'burger',
    'salad': 'salad',
    'fish': 'fish',
    'seafood': 'fish',
    'egg': 'egg',
    'eggs': 'egg',
    'fruit': 'fruit',
    'vegetable': 'vegetable',
    'milk': 'milk',

    // Travel & Urban
    'bicycle': 'bicycle',
    'bike': 'bicycle',
    'cycle': 'bicycle',
    'car': 'car',
    'automobile': 'car',
    'traffic light': 'traffic light',

    // Human & Body Parts
    'hand': 'hand',
    'hands': 'hand',
    'palm': 'hand',
    'finger': 'hand',
    'fingers': 'hand',
    'arm': 'hand',
    'wrist': 'hand',
    'person': 'person',
    'human': 'person',
    'face': 'face',
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
      case 'food':
      case 'chicken':
      case 'ice cream':
      case 'dessert':
      case 'snack':
      case 'meat':
      case 'rice':
      case 'noodles':
      case 'bread':
      case 'soup':
      case 'salad':
      case 'fish':
      case 'egg':
      case 'burger':
      case 'fruit':
      case 'vegetable':
      case 'milk':
      case 'clock':
      case 'trash can':
      case 'bucket':
      case 'cat':
      case 'dog':
      case 'bird':
      case 'hand':
      case 'person':
      case 'face':
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
    'trash can': const LexiconEntry(
      labelEn: 'Trash Can',
      targetWord: 'ゴミ箱',
      secondaryScript: 'ごみばこ',
      transliteration: 'gomibako',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N4',
    ),
    'bucket': const LexiconEntry(
      labelEn: 'Bucket',
      targetWord: 'バケツ',
      secondaryScript: 'ばけつ',
      transliteration: 'baketsu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
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
    'food': const LexiconEntry(
      labelEn: 'Food',
      targetWord: '食べ物',
      secondaryScript: 'たべもの',
      transliteration: 'tabemono',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'chicken': const LexiconEntry(
      labelEn: 'Chicken',
      targetWord: '鶏肉',
      secondaryScript: 'とりにく',
      transliteration: 'toriniku',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'ice cream': const LexiconEntry(
      labelEn: 'Ice Cream',
      targetWord: 'アイスクリーム',
      secondaryScript: 'あいすくりーむ',
      transliteration: 'aisukuriimu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'dessert': const LexiconEntry(
      labelEn: 'Dessert',
      targetWord: 'デザート',
      secondaryScript: 'でざーと',
      transliteration: 'dezaato',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'snack': const LexiconEntry(
      labelEn: 'Snack',
      targetWord: 'おやつ',
      secondaryScript: 'おやつ',
      transliteration: 'oyatsu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'meat': const LexiconEntry(
      labelEn: 'Meat',
      targetWord: '肉',
      secondaryScript: 'にく',
      transliteration: 'niku',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'rice': const LexiconEntry(
      labelEn: 'Rice',
      targetWord: 'ご飯',
      secondaryScript: 'ごはん',
      transliteration: 'gohan',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'noodles': const LexiconEntry(
      labelEn: 'Noodles',
      targetWord: '麺',
      secondaryScript: 'めん',
      transliteration: 'men',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'bread': const LexiconEntry(
      labelEn: 'Bread',
      targetWord: 'パン',
      secondaryScript: 'ぱん',
      transliteration: 'pan',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'soup': const LexiconEntry(
      labelEn: 'Soup',
      targetWord: 'スープ',
      secondaryScript: 'すーぷ',
      transliteration: 'suupu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'salad': const LexiconEntry(
      labelEn: 'Salad',
      targetWord: 'サラダ',
      secondaryScript: 'さらだ',
      transliteration: 'sarada',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'fish': const LexiconEntry(
      labelEn: 'Fish',
      targetWord: '魚',
      secondaryScript: 'さかな',
      transliteration: 'sakana',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'egg': const LexiconEntry(
      labelEn: 'Egg',
      targetWord: '卵',
      secondaryScript: 'たまご',
      transliteration: 'tamago',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'burger': const LexiconEntry(
      labelEn: 'Burger',
      targetWord: 'ハンバーガー',
      secondaryScript: 'はんばーがー',
      transliteration: 'hanbaagaa',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'fruit': const LexiconEntry(
      labelEn: 'Fruit',
      targetWord: '果物',
      secondaryScript: 'くだもの',
      transliteration: 'kudamono',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'vegetable': const LexiconEntry(
      labelEn: 'Vegetable',
      targetWord: '野菜',
      secondaryScript: 'やさい',
      transliteration: 'yasai',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'milk': const LexiconEntry(
      labelEn: 'Milk',
      targetWord: '牛乳',
      secondaryScript: 'ぎゅうにゅう',
      transliteration: 'gyuunyuu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),

    // Human & Body Parts
    'hand': const LexiconEntry(
      labelEn: 'Hand',
      targetWord: '手',
      secondaryScript: 'て',
      transliteration: 'te',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'person': const LexiconEntry(
      labelEn: 'Person',
      targetWord: '人',
      secondaryScript: 'ひと',
      transliteration: 'hito',
      partOfSpeech: 'Noun',
      difficultyLevel: 'N5',
    ),
    'face': const LexiconEntry(
      labelEn: 'Face',
      targetWord: '顔',
      secondaryScript: 'かお',
      transliteration: 'kao',
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
    'trash can': LexiconEntry(
      labelEn: 'Trash Can',
      targetWord: BaybayinEngine.transliterate('basurahan'),
      secondaryScript: 'basurahan',
      transliteration: '[ba-su-ra-han]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'bucket': LexiconEntry(
      labelEn: 'Bucket',
      targetWord: BaybayinEngine.transliterate('timba'),
      secondaryScript: 'timba',
      transliteration: '[tim-ba]',
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
    'food': LexiconEntry(
      labelEn: 'Food',
      targetWord: BaybayinEngine.transliterate('pagkain'),
      secondaryScript: 'pagkain',
      transliteration: '[pag-ka-in]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'chicken': LexiconEntry(
      labelEn: 'Chicken',
      targetWord: BaybayinEngine.transliterate('manok'),
      secondaryScript: 'manok',
      transliteration: '[ma-nok]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'ice cream': LexiconEntry(
      labelEn: 'Ice Cream',
      targetWord: BaybayinEngine.transliterate('sorbetes'),
      secondaryScript: 'sorbetes',
      transliteration: '[sor-be-tes]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'dessert': LexiconEntry(
      labelEn: 'Dessert',
      targetWord: BaybayinEngine.transliterate('himagas'),
      secondaryScript: 'himagas',
      transliteration: '[hi-ma-gas]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'snack': LexiconEntry(
      labelEn: 'Snack',
      targetWord: BaybayinEngine.transliterate('meryenda'),
      secondaryScript: 'meryenda',
      transliteration: '[mer-yen-da]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'meat': LexiconEntry(
      labelEn: 'Meat',
      targetWord: BaybayinEngine.transliterate('karne'),
      secondaryScript: 'karne',
      transliteration: '[kar-ne]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'rice': LexiconEntry(
      labelEn: 'Rice',
      targetWord: BaybayinEngine.transliterate('kanin'),
      secondaryScript: 'kanin',
      transliteration: '[ka-nin]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'noodles': LexiconEntry(
      labelEn: 'Noodles',
      targetWord: BaybayinEngine.transliterate('pansit'),
      secondaryScript: 'pansit',
      transliteration: '[pan-sit]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'bread': LexiconEntry(
      labelEn: 'Bread',
      targetWord: BaybayinEngine.transliterate('tinapay'),
      secondaryScript: 'tinapay',
      transliteration: '[ti-na-pay]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'soup': LexiconEntry(
      labelEn: 'Soup',
      targetWord: BaybayinEngine.transliterate('sopas'),
      secondaryScript: 'sopas',
      transliteration: '[so-pas]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'salad': LexiconEntry(
      labelEn: 'Salad',
      targetWord: BaybayinEngine.transliterate('ensalada'),
      secondaryScript: 'ensalada',
      transliteration: '[en-sa-la-da]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'fish': LexiconEntry(
      labelEn: 'Fish',
      targetWord: BaybayinEngine.transliterate('isda'),
      secondaryScript: 'isda',
      transliteration: '[is-da]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'egg': LexiconEntry(
      labelEn: 'Egg',
      targetWord: BaybayinEngine.transliterate('itlog'),
      secondaryScript: 'itlog',
      transliteration: '[it-log]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'burger': LexiconEntry(
      labelEn: 'Burger',
      targetWord: BaybayinEngine.transliterate('hamburjer'),
      secondaryScript: 'hamburjer',
      transliteration: '[ham-bur-jer]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'fruit': LexiconEntry(
      labelEn: 'Fruit',
      targetWord: BaybayinEngine.transliterate('prutas'),
      secondaryScript: 'prutas',
      transliteration: '[pru-tas]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'vegetable': LexiconEntry(
      labelEn: 'Vegetable',
      targetWord: BaybayinEngine.transliterate('gulay'),
      secondaryScript: 'gulay',
      transliteration: '[gu-lay]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'milk': LexiconEntry(
      labelEn: 'Milk',
      targetWord: BaybayinEngine.transliterate('gatas'),
      secondaryScript: 'gatas',
      transliteration: '[ga-tas]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),

    // Human & Body Parts
    'hand': LexiconEntry(
      labelEn: 'Hand',
      targetWord: BaybayinEngine.transliterate('kamay'),
      secondaryScript: 'kamay',
      transliteration: '[ka-may]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'person': LexiconEntry(
      labelEn: 'Person',
      targetWord: BaybayinEngine.transliterate('tao'),
      secondaryScript: 'tao',
      transliteration: '[ta-o]',
      partOfSpeech: 'Noun',
      difficultyLevel: 'A1',
    ),
    'face': LexiconEntry(
      labelEn: 'Face',
      targetWord: BaybayinEngine.transliterate('mukha'),
      secondaryScript: 'mukha',
      transliteration: '[muk-ha]',
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
    'trash can': const LexiconEntry(
      labelEn: 'Trash Can',
      targetWord: 'cubo de basura',
      secondaryScript: 'el cubo de basura',
      transliteration: '[koo-boh deh bah-soo-rah]',
      partOfSpeech: 'Sustantivo',
      difficultyLevel: 'A1',
    ),
    'bucket': const LexiconEntry(
      labelEn: 'Bucket',
      targetWord: 'cubo',
      secondaryScript: 'el cubo',
      transliteration: '[koo-boh]',
      partOfSpeech: 'Sustantivo',
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

    // Foods
    'apple': const LexiconEntry(
      labelEn: 'Apple',
      targetWord: 'Manzana',
      secondaryScript: 'la manzana',
      transliteration: '[mahn-sah-nah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'banana': const LexiconEntry(
      labelEn: 'Banana',
      targetWord: 'Plátano',
      secondaryScript: 'el plátano',
      transliteration: '[plah-tah-noh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'orange': const LexiconEntry(
      labelEn: 'Orange',
      targetWord: 'Naranja',
      secondaryScript: 'la naranja',
      transliteration: '[nah-rahn-hah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'pizza': const LexiconEntry(
      labelEn: 'Pizza',
      targetWord: 'Pizza',
      secondaryScript: 'la pizza',
      transliteration: '[peet-sah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'cake': const LexiconEntry(
      labelEn: 'Cake',
      targetWord: 'Pastel',
      secondaryScript: 'el pastel',
      transliteration: '[pahs-tehl]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'food': const LexiconEntry(
      labelEn: 'Food',
      targetWord: 'Comida',
      secondaryScript: 'la comida',
      transliteration: '[koh-mee-dah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'chicken': const LexiconEntry(
      labelEn: 'Chicken',
      targetWord: 'Pollo',
      secondaryScript: 'el pollo',
      transliteration: '[poh-yoh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'ice cream': const LexiconEntry(
      labelEn: 'Ice Cream',
      targetWord: 'Helado',
      secondaryScript: 'el helado',
      transliteration: '[eh-lah-doh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'dessert': const LexiconEntry(
      labelEn: 'Dessert',
      targetWord: 'Postre',
      secondaryScript: 'el postre',
      transliteration: '[pohs-treh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'snack': const LexiconEntry(
      labelEn: 'Snack',
      targetWord: 'Merienda',
      secondaryScript: 'la merienda',
      transliteration: '[meh-ryehn-dah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'meat': const LexiconEntry(
      labelEn: 'Meat',
      targetWord: 'Carne',
      secondaryScript: 'la carne',
      transliteration: '[kahr-neh]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'rice': const LexiconEntry(
      labelEn: 'Rice',
      targetWord: 'Arroz',
      secondaryScript: 'el arroz',
      transliteration: '[ah-rrohs]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'noodles': const LexiconEntry(
      labelEn: 'Noodles',
      targetWord: 'Fideos',
      secondaryScript: 'los fideos',
      transliteration: '[fee-deh-ohs]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'bread': const LexiconEntry(
      labelEn: 'Bread',
      targetWord: 'Pan',
      secondaryScript: 'el pan',
      transliteration: '[pahn]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'soup': const LexiconEntry(
      labelEn: 'Soup',
      targetWord: 'Sopa',
      secondaryScript: 'la sopa',
      transliteration: '[soh-pah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'salad': const LexiconEntry(
      labelEn: 'Salad',
      targetWord: 'Ensalada',
      secondaryScript: 'la ensalada',
      transliteration: '[ehn-sah-lah-dah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'fish': const LexiconEntry(
      labelEn: 'Fish',
      targetWord: 'Pescado',
      secondaryScript: 'el pescado',
      transliteration: '[pehs-kah-doh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'egg': const LexiconEntry(
      labelEn: 'Egg',
      targetWord: 'Huevo',
      secondaryScript: 'el huevo',
      transliteration: '[weh-voh]',
      partOfSpeech: 'Noun • m',
      difficultyLevel: 'A1',
    ),
    'burger': const LexiconEntry(
      labelEn: 'Burger',
      targetWord: 'Hamburguesa',
      secondaryScript: 'la hamburguesa',
      transliteration: '[ahm-boor-geh-sah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'fruit': const LexiconEntry(
      labelEn: 'Fruit',
      targetWord: 'Fruta',
      secondaryScript: 'la fruta',
      transliteration: '[froo-tah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'vegetable': const LexiconEntry(
      labelEn: 'Vegetable',
      targetWord: 'Verdura',
      secondaryScript: 'la verdura',
      transliteration: '[behr-doo-rah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'milk': const LexiconEntry(
      labelEn: 'Milk',
      targetWord: 'Leche',
      secondaryScript: 'la leche',
      transliteration: '[leh-cheh]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),

    // Human & Body Parts
    'hand': const LexiconEntry(
      labelEn: 'Hand',
      targetWord: 'Mano',
      secondaryScript: 'la mano',
      transliteration: '[mah-noh]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'person': const LexiconEntry(
      labelEn: 'Person',
      targetWord: 'Persona',
      secondaryScript: 'la persona',
      transliteration: '[pehr-soh-nah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
    'face': const LexiconEntry(
      labelEn: 'Face',
      targetWord: 'Cara',
      secondaryScript: 'la cara',
      transliteration: '[kah-rah]',
      partOfSpeech: 'Noun • f',
      difficultyLevel: 'A1',
    ),
  };

  // -------------------------------------------------------------
  // MANDARIN CHINESE (Simplified Hanzi / Pinyin with tones / HSK)
  // -------------------------------------------------------------
  static final Map<String, LexiconEntry> _mandarin = {
    // Everyday kitchen / cafe / drinkware
    'cup': const LexiconEntry(
      labelEn: 'Cup',
      targetWord: '杯子',
      secondaryScript: 'bēizi',
      transliteration: 'bēizi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'mug': const LexiconEntry(
      labelEn: 'Mug',
      targetWord: '马克杯',
      secondaryScript: 'mǎkèbēi',
      transliteration: 'mǎkèbēi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'coffee cup': const LexiconEntry(
      labelEn: 'Coffee Cup',
      targetWord: '咖啡杯',
      secondaryScript: 'kāfēibēi',
      transliteration: 'kāfēibēi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'coffee': const LexiconEntry(
      labelEn: 'Coffee',
      targetWord: '咖啡',
      secondaryScript: 'kāfēi',
      transliteration: 'kāfēi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'tea': const LexiconEntry(
      labelEn: 'Tea',
      targetWord: '茶',
      secondaryScript: 'chá',
      transliteration: 'chá',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'water': const LexiconEntry(
      labelEn: 'Water',
      targetWord: '水',
      secondaryScript: 'shuǐ',
      transliteration: 'shuǐ',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'bottle': const LexiconEntry(
      labelEn: 'Bottle',
      targetWord: '瓶子',
      secondaryScript: 'píngzi',
      transliteration: 'píngzi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'wine glass': const LexiconEntry(
      labelEn: 'Wine Glass',
      targetWord: '酒杯',
      secondaryScript: 'jiǔbēi',
      transliteration: 'jiǔbēi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'bowl': const LexiconEntry(
      labelEn: 'Bowl',
      targetWord: '碗',
      secondaryScript: 'wǎn',
      transliteration: 'wǎn',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'plate': const LexiconEntry(
      labelEn: 'Plate',
      targetWord: '盘子',
      secondaryScript: 'pánzi',
      transliteration: 'pánzi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'tableware': const LexiconEntry(
      labelEn: 'Tableware',
      targetWord: '餐具',
      secondaryScript: 'cānjù',
      transliteration: 'cānjù',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK3',
    ),
    'fork': const LexiconEntry(
      labelEn: 'Fork',
      targetWord: '叉子',
      secondaryScript: 'chāzi',
      transliteration: 'chāzi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'spoon': const LexiconEntry(
      labelEn: 'Spoon',
      targetWord: '勺子',
      secondaryScript: 'sháozi',
      transliteration: 'sháozi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'knife': const LexiconEntry(
      labelEn: 'Knife',
      targetWord: '刀',
      secondaryScript: 'dāo',
      transliteration: 'dāo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),

    // Furniture & Interior
    'chair': const LexiconEntry(
      labelEn: 'Chair',
      targetWord: '椅子',
      secondaryScript: 'yǐzi',
      transliteration: 'yǐzi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'couch': const LexiconEntry(
      labelEn: 'Sofa',
      targetWord: '沙发',
      secondaryScript: 'shāfā',
      transliteration: 'shāfā',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'potted plant': const LexiconEntry(
      labelEn: 'Potted Plant',
      targetWord: '盆栽',
      secondaryScript: 'pénzāi',
      transliteration: 'pénzāi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK3',
    ),
    'bed': const LexiconEntry(
      labelEn: 'Bed',
      targetWord: '床',
      secondaryScript: 'chuáng',
      transliteration: 'chuáng',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'dining table': const LexiconEntry(
      labelEn: 'Dining Table',
      targetWord: '餐桌',
      secondaryScript: 'cānzhuō',
      transliteration: 'cānzhuō',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'desk': const LexiconEntry(
      labelEn: 'Desk',
      targetWord: '书桌',
      secondaryScript: 'shūzhuō',
      transliteration: 'shūzhuō',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'window': const LexiconEntry(
      labelEn: 'Window',
      targetWord: '窗户',
      secondaryScript: 'chuānghu',
      transliteration: 'chuānghu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'door': const LexiconEntry(
      labelEn: 'Door',
      targetWord: '门',
      secondaryScript: 'mén',
      transliteration: 'mén',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'trash can': const LexiconEntry(
      labelEn: 'Trash Can',
      targetWord: '垃圾桶',
      secondaryScript: 'lājītǒng',
      transliteration: 'lājītǒng',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'bucket': const LexiconEntry(
      labelEn: 'Bucket',
      targetWord: '水桶',
      secondaryScript: 'shuǐtǒng',
      transliteration: 'shuǐtǒng',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),

    // Tech & Personal Items
    'laptop': const LexiconEntry(
      labelEn: 'Laptop',
      targetWord: '笔记本电脑',
      secondaryScript: 'bǐjìběn diànnǎo',
      transliteration: 'bǐjìběn diànnǎo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'cell phone': const LexiconEntry(
      labelEn: 'Mobile Phone',
      targetWord: '手机',
      secondaryScript: 'shǒujī',
      transliteration: 'shǒujī',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'book': const LexiconEntry(
      labelEn: 'Book',
      targetWord: '书',
      secondaryScript: 'shū',
      transliteration: 'shū',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'pen': const LexiconEntry(
      labelEn: 'Pen',
      targetWord: '笔',
      secondaryScript: 'bǐ',
      transliteration: 'bǐ',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'backpack': const LexiconEntry(
      labelEn: 'Backpack',
      targetWord: '背包',
      secondaryScript: 'bēibāo',
      transliteration: 'bēibāo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'umbrella': const LexiconEntry(
      labelEn: 'Umbrella',
      targetWord: '雨伞',
      secondaryScript: 'yǔsǎn',
      transliteration: 'yǔsǎn',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'clock': const LexiconEntry(
      labelEn: 'Clock',
      targetWord: '钟表',
      secondaryScript: 'zhōngbiǎo',
      transliteration: 'zhōngbiǎo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),

    // Animals & Nature
    'cat': const LexiconEntry(
      labelEn: 'Cat',
      targetWord: '猫',
      secondaryScript: 'māo',
      transliteration: 'māo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'dog': const LexiconEntry(
      labelEn: 'Dog',
      targetWord: '狗',
      secondaryScript: 'gǒu',
      transliteration: 'gǒu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'bird': const LexiconEntry(
      labelEn: 'Bird',
      targetWord: '鸟',
      secondaryScript: 'niǎo',
      transliteration: 'niǎo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'tree': const LexiconEntry(
      labelEn: 'Tree',
      targetWord: '树',
      secondaryScript: 'shù',
      transliteration: 'shù',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),

    // Foods
    'apple': const LexiconEntry(
      labelEn: 'Apple',
      targetWord: '苹果',
      secondaryScript: 'píngguǒ',
      transliteration: 'píngguǒ',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'banana': const LexiconEntry(
      labelEn: 'Banana',
      targetWord: '香蕉',
      secondaryScript: 'xiāngjiāo',
      transliteration: 'xiāngjiāo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'orange': const LexiconEntry(
      labelEn: 'Orange',
      targetWord: '橘子',
      secondaryScript: 'júzi',
      transliteration: 'júzi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'pizza': const LexiconEntry(
      labelEn: 'Pizza',
      targetWord: '比萨',
      secondaryScript: 'bǐsà',
      transliteration: 'bǐsà',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'cake': const LexiconEntry(
      labelEn: 'Cake',
      targetWord: '蛋糕',
      secondaryScript: 'dàngāo',
      transliteration: 'dàngāo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'food': const LexiconEntry(
      labelEn: 'Food',
      targetWord: '食物',
      secondaryScript: 'shíwù',
      transliteration: 'shíwù',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'chicken': const LexiconEntry(
      labelEn: 'Chicken',
      targetWord: '鸡肉',
      secondaryScript: 'jīròu',
      transliteration: 'jīròu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'ice cream': const LexiconEntry(
      labelEn: 'Ice Cream',
      targetWord: '冰淇淋',
      secondaryScript: 'bīngqílín',
      transliteration: 'bīngqílín',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'dessert': const LexiconEntry(
      labelEn: 'Dessert',
      targetWord: '甜点',
      secondaryScript: 'tiándiǎn',
      transliteration: 'tiándiǎn',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'snack': const LexiconEntry(
      labelEn: 'Snack',
      targetWord: '小吃',
      secondaryScript: 'xiǎochī',
      transliteration: 'xiǎochī',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'meat': const LexiconEntry(
      labelEn: 'Meat',
      targetWord: '肉',
      secondaryScript: 'ròu',
      transliteration: 'ròu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'rice': const LexiconEntry(
      labelEn: 'Rice',
      targetWord: '米饭',
      secondaryScript: 'mǐfàn',
      transliteration: 'mǐfàn',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'noodles': const LexiconEntry(
      labelEn: 'Noodles',
      targetWord: '面条',
      secondaryScript: 'miàntiáo',
      transliteration: 'miàntiáo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'bread': const LexiconEntry(
      labelEn: 'Bread',
      targetWord: '面包',
      secondaryScript: 'miànbāo',
      transliteration: 'miànbāo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'soup': const LexiconEntry(
      labelEn: 'Soup',
      targetWord: '汤',
      secondaryScript: 'tāng',
      transliteration: 'tāng',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'salad': const LexiconEntry(
      labelEn: 'Salad',
      targetWord: '沙拉',
      secondaryScript: 'shālā',
      transliteration: 'shālā',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'fish': const LexiconEntry(
      labelEn: 'Fish',
      targetWord: '鱼',
      secondaryScript: 'yú',
      transliteration: 'yú',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'egg': const LexiconEntry(
      labelEn: 'Egg',
      targetWord: '鸡蛋',
      secondaryScript: 'jīdàn',
      transliteration: 'jīdàn',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'burger': const LexiconEntry(
      labelEn: 'Burger',
      targetWord: '汉堡',
      secondaryScript: 'hànbǎo',
      transliteration: 'hànbǎo',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'fruit': const LexiconEntry(
      labelEn: 'Fruit',
      targetWord: '水果',
      secondaryScript: 'shuǐguǒ',
      transliteration: 'shuǐguǒ',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'vegetable': const LexiconEntry(
      labelEn: 'Vegetable',
      targetWord: '蔬菜',
      secondaryScript: 'shūcài',
      transliteration: 'shūcài',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'milk': const LexiconEntry(
      labelEn: 'Milk',
      targetWord: '牛奶',
      secondaryScript: 'niúnǎi',
      transliteration: 'niúnǎi',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),

    // Travel & Urban
    'bicycle': const LexiconEntry(
      labelEn: 'Bicycle',
      targetWord: '自行车',
      secondaryScript: 'zìxíngchē',
      transliteration: 'zìxíngchē',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'car': const LexiconEntry(
      labelEn: 'Car',
      targetWord: '汽车',
      secondaryScript: 'qìchē',
      transliteration: 'qìchē',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
    'motorcycle': const LexiconEntry(
      labelEn: 'Motorcycle',
      targetWord: '摩托车',
      secondaryScript: 'mótuōchē',
      transliteration: 'mótuōchē',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK3',
    ),

    // Human & Body Parts
    'hand': const LexiconEntry(
      labelEn: 'Hand',
      targetWord: '手',
      secondaryScript: 'shǒu',
      transliteration: 'shǒu',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'person': const LexiconEntry(
      labelEn: 'Person',
      targetWord: '人',
      secondaryScript: 'rén',
      transliteration: 'rén',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK1',
    ),
    'face': const LexiconEntry(
      labelEn: 'Face',
      targetWord: '脸',
      secondaryScript: 'liǎn',
      transliteration: 'liǎn',
      partOfSpeech: 'Noun',
      difficultyLevel: 'HSK2',
    ),
  };

  static String _cleanForComparison(String input) {
    var s = input.trim().toLowerCase();
    // Strip brackets, parentheses, punctuation, and bullets
    s = s.replaceAll(RegExp(r'[\[\]\(\)\{\}\.,;:\-_/\\·•]'), ' ');
    // Strip common leading articles
    for (final article in ['el ', 'la ', 'los ', 'las ', 'un ', 'una ', 'der ', 'die ', 'das ']) {
      if (s.startsWith(article)) {
        s = s.substring(article.length);
      }
    }
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Bidirectional reverse lookup: Given a target word, transliteration, or secondary script
  /// (e.g. '猫', 'neko', 'ねこ', 'pusa', 'gato'), finds the matching LexiconEntry across
  /// the multilingual offline dictionary.
  static LexiconEntry? reverseLookup({
    String? word,
    String? targetWord,
    String? transliteration,
    String? secondaryScript,
    String? langCode,
  }) {
    final queryCandidates = <String>[];
    void addCandidate(String? s) {
      if (s != null && s.trim().isNotEmpty) {
        final clean = _cleanForComparison(s);
        if (clean.isNotEmpty && !queryCandidates.contains(clean)) {
          queryCandidates.add(clean);
        }
        final rawClean = s.trim().toLowerCase();
        if (rawClean.isNotEmpty && !queryCandidates.contains(rawClean)) {
          queryCandidates.add(rawClean);
        }
      }
    }

    addCandidate(word);
    addCandidate(targetWord);
    addCandidate(transliteration);
    addCandidate(secondaryScript);

    if (queryCandidates.isEmpty) return null;

    final code = langCode?.trim().toLowerCase();
    final List<Map<String, LexiconEntry>> mapsToSearch = [];

    if (code == 'ja') {
      mapsToSearch.add(_japanese);
    } else if (code == 'fil' || code == 'tl') {
      mapsToSearch.add(_filipino);
    } else if (code == 'zh' || (code != null && code.startsWith('zh'))) {
      mapsToSearch.add(_mandarin);
    } else if (code == 'es') {
      mapsToSearch.add(_spanish);
    } else {
      mapsToSearch.addAll([_japanese, _filipino, _spanish, _mandarin]);
    }

    // Pass 1: exact matches within target language maps
    for (final dict in mapsToSearch) {
      for (final entry in dict.values) {
        final entryWords = [
          _cleanForComparison(entry.targetWord),
          _cleanForComparison(entry.transliteration),
          _cleanForComparison(entry.secondaryScript),
          _cleanForComparison(entry.labelEn),
          entry.targetWord.trim().toLowerCase(),
          entry.transliteration.trim().toLowerCase(),
          entry.secondaryScript.trim().toLowerCase(),
          entry.labelEn.trim().toLowerCase(),
        ];
        for (final query in queryCandidates) {
          if (entryWords.contains(query)) {
            return entry;
          }
        }
      }
    }

    // Pass 2: check all remaining dictionaries if not found yet
    final allMaps = [_japanese, _filipino, _spanish, _mandarin];
    for (final dict in allMaps) {
      if (mapsToSearch.contains(dict)) continue;
      for (final entry in dict.values) {
        final entryWords = [
          _cleanForComparison(entry.targetWord),
          _cleanForComparison(entry.transliteration),
          _cleanForComparison(entry.secondaryScript),
          _cleanForComparison(entry.labelEn),
          entry.targetWord.trim().toLowerCase(),
          entry.transliteration.trim().toLowerCase(),
          entry.secondaryScript.trim().toLowerCase(),
          entry.labelEn.trim().toLowerCase(),
        ];
        for (final query in queryCandidates) {
          if (entryWords.contains(query)) {
            return entry;
          }
        }
      }
    }

    return null;
  }

  /// Lookup a detected class name for a given language code (ja, fil, es, zh) with synonym normalization.
  /// If normal lookup fails (e.g. className is a target word, transliteration, or script like '猫' or 'neko'),
  /// seamlessly falls back to reverseLookup.
  static LexiconEntry? lookup({
    required String className,
    required String langCode,
  }) {
    final key = normalizeClassName(className);
    final code = langCode.trim().toLowerCase();
    LexiconEntry? result;
    if (code == 'ja') {
      result = _japanese[key];
    } else if (code == 'fil' || code == 'tl') {
      result = _filipino[key];
    } else if (code == 'zh' || code.startsWith('zh')) {
      result = _mandarin[key];
    } else {
      result = _spanish[key];
    }

    if (result != null) return result;

    // Resilient fallback: If className was actually a native word, romaji, or script,
    // reverse-lookup the dictionary.
    return reverseLookup(word: className, langCode: langCode);
  }

  /// Check if a detected class has rich offline mappings
  static bool hasMapping(String className) {
    final key = normalizeClassName(className);
    return _japanese.containsKey(key) ||
        _filipino.containsKey(key) ||
        _spanish.containsKey(key) ||
        _mandarin.containsKey(key);
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
    final lower = cleanLabel.toLowerCase();
    final code = langCode.trim().toLowerCase();

    // 1. Tagalog dictionary resolution if available
    if (code == 'fil' || code == 'tl') {
      final known = TagalogDictionaryService.instance.lookupByEnglish(cleanLabel);
      if (known != null) {
        return LexiconEntry(
          labelEn: cleanLabel,
          targetWord: known.baybayin,
          secondaryScript: known.word,
          transliteration: known.pronunciation,
          partOfSpeech: known.partOfSpeech,
          difficultyLevel: known.difficultyLevel,
        );
      }
    }

    // 2. Classify semantic category
    final isFood = lower.contains('food') ||
        lower.contains('dish') ||
        lower.contains('meal') ||
        lower.contains('cuisine') ||
        lower.contains('snack') ||
        lower.contains('dessert') ||
        lower.contains('sweet') ||
        lower.contains('meat') ||
        lower.contains('poultry') ||
        lower.contains('chicken') ||
        lower.contains('drink') ||
        lower.contains('beverage') ||
        lower.contains('dairy');
    final isAnimal = lower.contains('animal') ||
        lower.contains('pet') ||
        lower.contains('creature') ||
        lower.contains('wildlife');
    final isPlant = lower.contains('plant') ||
        lower.contains('flower') ||
        lower.contains('leaf') ||
        lower.contains('tree') ||
        lower.contains('flora');
    final isFurniture = lower.contains('furniture') ||
        lower.contains('table') ||
        lower.contains('chair') ||
        lower.contains('desk') ||
        lower.contains('shelf');
    final isTool = lower.contains('tool') ||
        lower.contains('device') ||
        lower.contains('instrument') ||
        lower.contains('gadget');

    if (code == 'ja') {
      if (isFood) {
        return const LexiconEntry(
          labelEn: 'Food',
          targetWord: '食べ物',
          secondaryScript: 'たべもの',
          transliteration: 'tabemono',
          partOfSpeech: 'Noun',
          difficultyLevel: 'N5',
        );
      } else if (isAnimal) {
        return const LexiconEntry(
          labelEn: 'Animal',
          targetWord: '動物',
          secondaryScript: 'どうぶつ',
          transliteration: 'doubutsu',
          partOfSpeech: 'Noun',
          difficultyLevel: 'N5',
        );
      } else if (isPlant) {
        return const LexiconEntry(
          labelEn: 'Plant',
          targetWord: '植物',
          secondaryScript: 'しょくぶつ',
          transliteration: 'shokubutsu',
          partOfSpeech: 'Noun',
          difficultyLevel: 'N5',
        );
      } else if (isFurniture) {
        return const LexiconEntry(
          labelEn: 'Furniture',
          targetWord: '家具',
          secondaryScript: 'かぐ',
          transliteration: 'kagu',
          partOfSpeech: 'Noun',
          difficultyLevel: 'N5',
        );
      } else if (isTool) {
        return const LexiconEntry(
          labelEn: 'Tool',
          targetWord: '道具',
          secondaryScript: 'どうぐ',
          transliteration: 'dougu',
          partOfSpeech: 'Noun',
          difficultyLevel: 'N5',
        );
      } else {
        return const LexiconEntry(
          labelEn: 'Item',
          targetWord: '物',
          secondaryScript: 'もの',
          transliteration: 'mono',
          partOfSpeech: 'Noun',
          difficultyLevel: 'N5',
        );
      }
    } else if (code == 'zh' || code.startsWith('zh')) {
      if (isFood) {
        return const LexiconEntry(
          labelEn: 'Food',
          targetWord: '食物',
          secondaryScript: 'shíwù',
          transliteration: 'shíwù',
          partOfSpeech: 'Noun',
          difficultyLevel: 'HSK1',
        );
      } else if (isAnimal) {
        return const LexiconEntry(
          labelEn: 'Animal',
          targetWord: '动物',
          secondaryScript: 'dòngwù',
          transliteration: 'dòngwù',
          partOfSpeech: 'Noun',
          difficultyLevel: 'HSK1',
        );
      } else if (isPlant) {
        return const LexiconEntry(
          labelEn: 'Plant',
          targetWord: '植物',
          secondaryScript: 'zhíwù',
          transliteration: 'zhíwù',
          partOfSpeech: 'Noun',
          difficultyLevel: 'HSK1',
        );
      } else if (isFurniture) {
        return const LexiconEntry(
          labelEn: 'Furniture',
          targetWord: '家具',
          secondaryScript: 'jiājù',
          transliteration: 'jiājù',
          partOfSpeech: 'Noun',
          difficultyLevel: 'HSK2',
        );
      } else if (isTool) {
        return const LexiconEntry(
          labelEn: 'Tool',
          targetWord: '工具',
          secondaryScript: 'gōngjù',
          transliteration: 'gōngjù',
          partOfSpeech: 'Noun',
          difficultyLevel: 'HSK2',
        );
      } else {
        return const LexiconEntry(
          labelEn: 'Item',
          targetWord: '物品',
          secondaryScript: 'wùpǐn',
          transliteration: 'wùpǐn',
          partOfSpeech: 'Noun',
          difficultyLevel: 'HSK1',
        );
      }
    } else if (code == 'fil' || code == 'tl') {
      if (isFood) {
        return LexiconEntry(
          labelEn: 'Food',
          targetWord: BaybayinEngine.transliterate('pagkain'),
          secondaryScript: 'pagkain',
          transliteration: '[pag-ka-in]',
          partOfSpeech: 'Noun',
          difficultyLevel: 'A1',
        );
      } else if (isAnimal) {
        return LexiconEntry(
          labelEn: 'Animal',
          targetWord: BaybayinEngine.transliterate('hayop'),
          secondaryScript: 'hayop',
          transliteration: '[ha-yop]',
          partOfSpeech: 'Noun',
          difficultyLevel: 'A1',
        );
      } else if (isPlant) {
        return LexiconEntry(
          labelEn: 'Plant',
          targetWord: BaybayinEngine.transliterate('halaman'),
          secondaryScript: 'halaman',
          transliteration: '[ha-la-man]',
          partOfSpeech: 'Noun',
          difficultyLevel: 'A1',
        );
      } else if (isFurniture) {
        return LexiconEntry(
          labelEn: 'Furniture',
          targetWord: BaybayinEngine.transliterate('kasangkapan'),
          secondaryScript: 'kasangkapan',
          transliteration: '[ka-sang-ka-pan]',
          partOfSpeech: 'Noun',
          difficultyLevel: 'A1',
        );
      } else if (isTool) {
        return LexiconEntry(
          labelEn: 'Tool',
          targetWord: BaybayinEngine.transliterate('kagamitan'),
          secondaryScript: 'kagamitan',
          transliteration: '[ka-ga-mi-tan]',
          partOfSpeech: 'Noun',
          difficultyLevel: 'A1',
        );
      } else {
        return LexiconEntry(
          labelEn: 'Item',
          targetWord: BaybayinEngine.transliterate('bagay'),
          secondaryScript: 'bagay',
          transliteration: '[ba-gay]',
          partOfSpeech: 'Noun',
          difficultyLevel: 'A1',
        );
      }
    } else {
      if (isFood) {
        return const LexiconEntry(
          labelEn: 'Food',
          targetWord: 'Comida',
          secondaryScript: 'la comida',
          transliteration: '[koh-mee-dah]',
          partOfSpeech: 'Noun • f',
          difficultyLevel: 'A1',
        );
      } else if (isAnimal) {
        return const LexiconEntry(
          labelEn: 'Animal',
          targetWord: 'Animal',
          secondaryScript: 'el animal',
          transliteration: '[ah-nee-mahl]',
          partOfSpeech: 'Noun • m',
          difficultyLevel: 'A1',
        );
      } else if (isPlant) {
        return const LexiconEntry(
          labelEn: 'Plant',
          targetWord: 'Planta',
          secondaryScript: 'la planta',
          transliteration: '[plahn-tah]',
          partOfSpeech: 'Noun • f',
          difficultyLevel: 'A1',
        );
      } else if (isFurniture) {
        return const LexiconEntry(
          labelEn: 'Furniture',
          targetWord: 'Mueble',
          secondaryScript: 'el mueble',
          transliteration: '[mweh-bleh]',
          partOfSpeech: 'Noun • m',
          difficultyLevel: 'A1',
        );
      } else if (isTool) {
        return const LexiconEntry(
          labelEn: 'Tool',
          targetWord: 'Herramienta',
          secondaryScript: 'la herramienta',
          transliteration: '[ehr-rah-myehn-tah]',
          partOfSpeech: 'Noun • f',
          difficultyLevel: 'A1',
        );
      } else {
        return const LexiconEntry(
          labelEn: 'Item',
          targetWord: 'Objeto',
          secondaryScript: 'el objeto',
          transliteration: '[ohb-heh-toh]',
          partOfSpeech: 'Noun • m',
          difficultyLevel: 'A1',
        );
      }
    }
  }
}
