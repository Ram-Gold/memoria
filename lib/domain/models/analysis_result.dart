import 'detected_object.dart';

class AnalysisResult {
  final String sessionId;
  final String languageCode;
  final String primaryObjectId;
  final String sceneDescription;
  final List<DetectedObject> detectedObjects;

  const AnalysisResult({
    required this.sessionId,
    required this.languageCode,
    required this.primaryObjectId,
    required this.sceneDescription,
    required this.detectedObjects,
  });

  DetectedObject? get primaryObject {
    for (final obj in detectedObjects) {
      if (obj.id == primaryObjectId) {
        return obj;
      }
    }
    return detectedObjects.isNotEmpty ? detectedObjects.first : null;
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final list = (json['detected_objects'] as List? ?? [])
        .map((e) => DetectedObject.fromJson(e as Map<String, dynamic>))
        .toList();

    return AnalysisResult(
      sessionId: json['session_id']?.toString() ?? '',
      languageCode: json['language_code']?.toString() ?? 'ja',
      primaryObjectId: json['primary_object_id']?.toString() ?? (list.isNotEmpty ? list.first.id : ''),
      sceneDescription: json['scene_description']?.toString() ?? '',
      detectedObjects: list,
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
