import '../../core/rag/models/rag_context.dart';
import 'detected_object.dart';

class AnalysisResult {
  final String sessionId;
  final String languageCode;
  final String primaryObjectId;
  final String sceneDescription;
  final List<DetectedObject> detectedObjects;
  final RagContext? ragContext;

  const AnalysisResult({
    required this.sessionId,
    required this.languageCode,
    required this.primaryObjectId,
    required this.sceneDescription,
    required this.detectedObjects,
    this.ragContext,
  });

  /// Returns only the detected objects that meet or exceed the confidence threshold
  List<DetectedObject> get confidentObjects =>
      detectedObjects.where((o) => o.isConfident()).toList();

  /// Returns objects meeting a specific confidence threshold
  List<DetectedObject> getConfidentObjects([double threshold = DetectedObject.defaultConfidenceThreshold]) =>
      detectedObjects.where((o) => o.isConfident(threshold)).toList();

  DetectedObject? get primaryObject {
    // 1. Prefer matching primaryObjectId if it meets the confidence threshold
    for (final obj in detectedObjects) {
      if (obj.id == primaryObjectId && obj.isConfident()) {
        return obj;
      }
    }
    // 2. Next, select the first object that meets the confidence threshold
    final confident = confidentObjects;
    if (confident.isNotEmpty) {
      return confident.first;
    }
    // 3. Fallback to primaryObjectId even if lower confidence (prevents empty/crash state)
    for (final obj in detectedObjects) {
      if (obj.id == primaryObjectId) {
        return obj;
      }
    }
    return detectedObjects.isNotEmpty ? detectedObjects.first : null;
  }

  AnalysisResult copyWith({
    String? sessionId,
    String? languageCode,
    String? primaryObjectId,
    String? sceneDescription,
    List<DetectedObject>? detectedObjects,
    RagContext? ragContext,
  }) {
    return AnalysisResult(
      sessionId: sessionId ?? this.sessionId,
      languageCode: languageCode ?? this.languageCode,
      primaryObjectId: primaryObjectId ?? this.primaryObjectId,
      sceneDescription: sceneDescription ?? this.sceneDescription,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      ragContext: ragContext ?? this.ragContext,
    );
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json, {RagContext? ragContext}) {
    final list = (json['detected_objects'] as List? ?? [])
        .map((e) => DetectedObject.fromJson(e as Map<String, dynamic>))
        .toList();

    return AnalysisResult(
      sessionId: json['session_id']?.toString() ?? '',
      languageCode: json['language_code']?.toString() ?? 'ja',
      primaryObjectId: json['primary_object_id']?.toString() ?? (list.isNotEmpty ? list.first.id : ''),
      sceneDescription: json['scene_description']?.toString() ?? '',
      detectedObjects: list,
      ragContext: ragContext,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'language_code': languageCode,
      'primary_object_id': primaryObjectId,
      'scene_description': sceneDescription,
      'detected_objects': detectedObjects.map((e) => e.toJson()).toList(),
    };
  }
}
