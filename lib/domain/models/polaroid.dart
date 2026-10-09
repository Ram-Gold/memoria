import 'detected_object.dart';

class Polaroid {
  final String id;
  final String imagePath;
  final String outputImagePath;
  final String languageCode;
  final String selectedObjectId;
  final String selectedWord;
  final String? secondaryScript;
  final String? transliteration;
  final String? partOfSpeech;
  final String? difficultyLevel;
  final double textX;
  final double textY;
  final String layoutId;
  final bool isFavorite;
  final DateTime createdAt;
  final List<DetectedObject> detectedObjects;

  const Polaroid({
    required this.id,
    required this.imagePath,
    required this.outputImagePath,
    required this.languageCode,
    required this.selectedObjectId,
    required this.selectedWord,
    this.secondaryScript,
    this.transliteration,
    this.partOfSpeech,
    this.difficultyLevel,
    this.textX = 0.5,
    this.textY = 0.88,
    this.layoutId = 'classic',
    this.isFavorite = false,
    required this.createdAt,
    this.detectedObjects = const [],
  });

  Polaroid copyWith({
    String? id,
    String? imagePath,
    String? outputImagePath,
    String? languageCode,
    String? selectedObjectId,
    String? selectedWord,
    String? secondaryScript,
    String? transliteration,
    String? partOfSpeech,
    String? difficultyLevel,
    double? textX,
    double? textY,
    String? layoutId,
    bool? isFavorite,
    DateTime? createdAt,
    List<DetectedObject>? detectedObjects,
  }) {
    return Polaroid(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      outputImagePath: outputImagePath ?? this.outputImagePath,
      languageCode: languageCode ?? this.languageCode,
      selectedObjectId: selectedObjectId ?? this.selectedObjectId,
      selectedWord: selectedWord ?? this.selectedWord,
      secondaryScript: secondaryScript ?? this.secondaryScript,
      transliteration: transliteration ?? this.transliteration,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      textX: textX ?? this.textX,
      textY: textY ?? this.textY,
      layoutId: layoutId ?? this.layoutId,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      detectedObjects: detectedObjects ?? this.detectedObjects,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'output_image_path': outputImagePath,
      'language_code': languageCode,
      'selected_object_id': selectedObjectId,
      'selected_word': selectedWord,
      'secondary_script': secondaryScript,
      'transliteration': transliteration,
      'part_of_speech': partOfSpeech,
      'difficulty_level': difficultyLevel,
      'text_x': textX,
      'text_y': textY,
      'layout_id': layoutId,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Polaroid.fromDbMap(Map<String, dynamic> map, {List<DetectedObject> objects = const []}) {
    return Polaroid(
      id: map['id']?.toString() ?? '',
      imagePath: map['image_path']?.toString() ?? '',
      outputImagePath: map['output_image_path']?.toString() ?? '',
      languageCode: map['language_code']?.toString() ?? 'ja',
      selectedObjectId: map['selected_object_id']?.toString() ?? '',
      selectedWord: map['selected_word']?.toString() ?? '',
      secondaryScript: map['secondary_script']?.toString(),
      transliteration: map['transliteration']?.toString(),
      partOfSpeech: map['part_of_speech']?.toString(),
      difficultyLevel: map['difficulty_level']?.toString(),
      textX: (map['text_x'] as num?)?.toDouble() ?? 0.5,
      textY: (map['text_y'] as num?)?.toDouble() ?? 0.88,
      layoutId: map['layout_id']?.toString() ?? 'classic',
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      detectedObjects: objects,
    );
  }
}
