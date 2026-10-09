class DetectedObject {
  final String id;
  final String polaroidId;
  final String labelEn;
  final String targetWord;
  final String? secondaryScript;
  final String? transliteration;
  final String? partOfSpeech;
  final String? difficultyLevel;
  final List<int> box; // [ymin, xmin, ymax, xmax] (0 to 1000)

  const DetectedObject({
    required this.id,
    this.polaroidId = '',
    required this.labelEn,
    required this.targetWord,
    this.secondaryScript,
    this.transliteration,
    this.partOfSpeech,
    this.difficultyLevel,
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

    return DetectedObject(
      id: json['id']?.toString() ?? 'obj_0',
      polaroidId: polaroidId,
      labelEn: json['label_en']?.toString() ?? 'object',
      targetWord: json['target_word']?.toString() ?? '',
      secondaryScript: json['secondary_script']?.toString(),
      transliteration: json['transliteration']?.toString(),
      partOfSpeech: json['part_of_speech']?.toString() ?? 'Noun',
      difficultyLevel: json['difficulty_level']?.toString() ?? 'A1',
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
      box: [
        (map['box_ymin'] as num?)?.toInt() ?? 0,
        (map['box_xmin'] as num?)?.toInt() ?? 0,
        (map['box_ymax'] as num?)?.toInt() ?? 1000,
        (map['box_xmax'] as num?)?.toInt() ?? 1000,
      ],
    );
  }
}
