import '../../data/services/local_object_lexicon.dart';
import 'detected_object.dart';

class Polaroid {
  final String id;
  final String imagePath;
  final String outputImagePath;
  final String languageCode;
  final String selectedObjectId;
  final String selectedWord;
  final String? labelEn;
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
    this.labelEn,
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
    String? labelEn,
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
      labelEn: labelEn ?? this.labelEn,
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
      'label_en': labelEn,
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
      labelEn: map['label_en']?.toString(),
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

  /// Foolproof resolution of the authentic English meaning for this polaroid.
  /// Guarantees that vocabulary never displays placeholder artifacts.
  String get resolvedEnglishLabel {
    // 1. Direct labelEn stored on the Polaroid
    if (labelEn != null && labelEn!.trim().isNotEmpty && labelEn!.trim().toLowerCase() != 'object') {
      return labelEn!.trim();
    }

    // 2. Object matching selectedObjectId
    if (selectedObjectId.isNotEmpty) {
      for (final obj in detectedObjects) {
        if (obj.id == selectedObjectId &&
            obj.labelEn.trim().isNotEmpty &&
            obj.labelEn.trim().toLowerCase() != 'object') {
          return obj.labelEn.trim();
        }
      }
    }

    // 3. Object matching targetWord or transliteration
    for (final obj in detectedObjects) {
      final matchesWord = obj.targetWord.trim().toLowerCase() == selectedWord.trim().toLowerCase();
      final matchesTranslit = transliteration != null &&
          transliteration!.trim().isNotEmpty &&
          obj.transliteration?.trim().toLowerCase() == transliteration!.trim().toLowerCase();
      if ((matchesWord || matchesTranslit) &&
          obj.labelEn.trim().isNotEmpty &&
          obj.labelEn.trim().toLowerCase() != 'object') {
        return obj.labelEn.trim();
      }
    }

    // 4. Reverse dictionary lookup using selectedWord, transliteration, secondaryScript
    final reverse = LocalObjectLexicon.reverseLookup(
      targetWord: selectedWord,
      transliteration: transliteration,
      secondaryScript: secondaryScript,
      langCode: languageCode,
    );
    if (reverse != null && reverse.labelEn.trim().isNotEmpty) {
      return reverse.labelEn.trim();
    }

    // 5. Forward lookup in dictionary (if selectedWord was already English)
    final normal = LocalObjectLexicon.lookup(
      className: selectedWord,
      langCode: languageCode,
    );
    if (normal != null && normal.labelEn.trim().isNotEmpty) {
      return normal.labelEn.trim();
    }

    // 6. First non-generic object in detectedObjects
    for (final obj in detectedObjects) {
      if (obj.labelEn.trim().isNotEmpty && obj.labelEn.trim().toLowerCase() != 'object') {
        return obj.labelEn.trim();
      }
    }

    // 7. Clean capitalized transliteration
    if (transliteration != null && transliteration!.trim().isNotEmpty) {
      final clean = transliteration!.trim().replaceAll(RegExp(r'[\[\]\(\)]'), '');
      if (clean.isNotEmpty) {
        return clean[0].toUpperCase() + clean.substring(1);
      }
    }

    // 8. Safe ultimate fallback (never "Language learning artifact")
    return selectedWord.isNotEmpty ? selectedWord : 'Item';
  }
}
