import '../../data/services/local_object_lexicon.dart';

class DetectedObject {
  final String id;
  final String polaroidId;
  final String labelEn;
  final String targetWord;
  final String? secondaryScript;
  final String? transliteration;
  final String? partOfSpeech;
  final String? difficultyLevel;
  final double confidence;
  final List<int> box; // [ymin, xmin, ymax, xmax] (0 to 1000)

  static const double defaultConfidenceThreshold = 0.60;

  const DetectedObject({
    required this.id,
    this.polaroidId = '',
    required this.labelEn,
    required this.targetWord,
    this.secondaryScript,
    this.transliteration,
    this.partOfSpeech,
    this.difficultyLevel,
    this.confidence = 1.0,
    required this.box,
  });

  DetectedObject copyWith({
    String? id,
    String? polaroidId,
    String? labelEn,
    String? targetWord,
    String? secondaryScript,
    String? transliteration,
    String? partOfSpeech,
    String? difficultyLevel,
    double? confidence,
    List<int> box = const [],
  }) {
    return DetectedObject(
      id: id ?? this.id,
      polaroidId: polaroidId ?? this.polaroidId,
      labelEn: labelEn ?? this.labelEn,
      targetWord: targetWord ?? this.targetWord,
      secondaryScript: secondaryScript ?? this.secondaryScript,
      transliteration: transliteration ?? this.transliteration,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      confidence: confidence ?? this.confidence,
      box: box.isNotEmpty ? box : this.box,
    );
  }

  factory DetectedObject.fromJson(Map<String, dynamic> json, {String polaroidId = ''}) {
    List<int> parsedBox = [0, 0, 1000, 1000];
    if (json['box_2d'] is List) {
      parsedBox = (json['box_2d'] as List).map((e) => (e as num).toInt()).toList();
    } else if (json['bounding_box'] is List) {
      parsedBox = (json['bounding_box'] as List).map((e) => (e as num).toInt()).toList();
    }

    // Support confidence / confidence_score / confidentiality variations
    double parsedConfidence = 1.0;
    final rawConf = json['confidence'] ??
        json['confidence_score'] ??
        json['confidenciality_score'] ??
        json['confidentiality_score'] ??
        json['confidenciality'];
    if (rawConf is num) {
      parsedConfidence = rawConf.toDouble();
      // Normalize if provided on a 0-100 scale
      if (parsedConfidence > 1.0 && parsedConfidence <= 100.0) {
        parsedConfidence /= 100.0;
      }
    }

    // Flexible extraction of English label from common LLM output key variations
    String extractedLabelEn = (json['label_en'] ??
            json['english_label'] ??
            json['english_meaning'] ??
            json['english'] ??
            json['meaning'] ??
            json['label'] ??
            json['translation'] ??
            json['name'])
        ?.toString()
        .trim() ??
        '';

    final targetWord = (json['target_word'] ??
            json['targetWord'] ??
            json['word'] ??
            json['target'])
        ?.toString()
        .trim() ??
        '';

    final transliteration = (json['transliteration'] ??
            json['romaji'] ??
            json['pinyin'] ??
            json['pronunciation'] ??
            json['phonetic'])
        ?.toString()
        .trim();

    final secondaryScript = (json['secondary_script'] ??
            json['secondaryScript'] ??
            json['script'] ??
            json['kana'] ??
            json['furigana'] ??
            json['reading'])
        ?.toString()
        .trim();

    // If label_en is missing, empty, or generic ('object', 'item', 'unknown'),
    // perform reverse lookup in LocalObjectLexicon
    if (extractedLabelEn.isEmpty ||
        extractedLabelEn.toLowerCase() == 'object' ||
        extractedLabelEn.toLowerCase() == 'item' ||
        extractedLabelEn.toLowerCase() == 'unknown') {
      final rev = LocalObjectLexicon.reverseLookup(
        targetWord: targetWord,
        transliteration: transliteration,
        secondaryScript: secondaryScript,
      );
      if (rev != null && rev.labelEn.isNotEmpty) {
        extractedLabelEn = rev.labelEn;
      }
    }

    if (extractedLabelEn.isEmpty) {
      extractedLabelEn = 'object';
    }

    return DetectedObject(
      id: json['id']?.toString() ?? 'obj_0',
      polaroidId: polaroidId,
      labelEn: extractedLabelEn,
      targetWord: targetWord,
      secondaryScript: secondaryScript,
      transliteration: transliteration,
      partOfSpeech: json['part_of_speech']?.toString() ?? json['pos']?.toString() ?? 'Noun',
      difficultyLevel: json['difficulty_level']?.toString() ?? json['level']?.toString() ?? 'A1',
      confidence: parsedConfidence.clamp(0.0, 1.0),
      box: parsedBox,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'polaroid_id': polaroidId,
      'label_en': labelEn,
      'target_word': targetWord,
      'secondary_script': secondaryScript,
      'transliteration': transliteration,
      'part_of_speech': partOfSpeech,
      'difficulty_level': difficultyLevel,
      'confidence': confidence,
      'box_2d': box,
    };
  }

  Map<String, dynamic> toDbMap(String polId) {
    return {
      'id': id,
      'polaroid_id': polId,
      'label_en': labelEn,
      'target_word': targetWord,
      'secondary_script': secondaryScript,
      'transliteration': transliteration,
      'part_of_speech': partOfSpeech,
      'difficulty_level': difficultyLevel,
      'confidence': confidence,
      'box_ymin': box.isNotEmpty ? box[0] : 0,
      'box_xmin': box.length > 1 ? box[1] : 0,
      'box_ymax': box.length > 2 ? box[2] : 1000,
      'box_xmax': box.length > 3 ? box[3] : 1000,
    };
  }

  factory DetectedObject.fromDbMap(Map<String, dynamic> map) {
    return DetectedObject(
      id: map['id']?.toString() ?? '',
      polaroidId: map['polaroid_id']?.toString() ?? '',
      labelEn: map['label_en']?.toString() ?? '',
      targetWord: map['target_word']?.toString() ?? '',
      secondaryScript: map['secondary_script']?.toString(),
      transliteration: map['transliteration']?.toString(),
      partOfSpeech: map['part_of_speech']?.toString(),
      difficultyLevel: map['difficulty_level']?.toString(),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      box: [
        (map['box_ymin'] as num?)?.toInt() ?? 0,
        (map['box_xmin'] as num?)?.toInt() ?? 0,
        (map['box_ymax'] as num?)?.toInt() ?? 1000,
        (map['box_xmax'] as num?)?.toInt() ?? 1000,
      ],
    );
  }

  /// Whether this detected object meets the required confidence threshold
  bool isConfident([double threshold = defaultConfidenceThreshold]) {
    return confidence >= threshold;
  }

  /// Percentage score (0 - 100) for display badges
  int get confidencePercentage => (confidence * 100).round().clamp(0, 100);
}
