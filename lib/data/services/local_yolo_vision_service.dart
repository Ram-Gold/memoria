import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../../core/languages/language_profile.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/services/vision_service.dart';
import 'local_object_lexicon.dart';
import 'mock_vision_service.dart';

/// Intelligent on-device local vision service that uses YOLO for real pixel
/// object detection paired with a rich, culturally accurate lexicon dictionary.
/// 
/// If YOLO native inference is unavailable on the current platform/hardware,
/// it gracefully falls back to the dynamic analog darkroom generator so
/// the app never crashes or stalls.
class LocalYoloVisionService implements VisionService {
  final MockVisionService _fallbackService = MockVisionService();
  YOLO? _yolo;
  bool _isYoloReady = false;
  bool _attemptedInit = false;

  LocalYoloVisionService();

  Future<bool> initialize() async {
    if (_attemptedInit) return _isYoloReady;
    _attemptedInit = true;

    // Only attempt native YOLO initialization on Android and iOS devices
    if (!Platform.isAndroid && !Platform.isIOS) {
      developer.log('YOLO native runtime is mobile-only. Using dynamic darkroom on desktop/test.', name: 'LocalYoloVisionService');
      _isYoloReady = false;
      return false;
    }

    try {
      // Use official lightweight YOLO model
      _yolo = YOLO(modelPath: 'yolo26n');
      final success = await _yolo!.loadModel();
      _isYoloReady = success;
      developer.log('YOLO model loaded successfully: $_isYoloReady', name: 'LocalYoloVisionService');
      return _isYoloReady;
    } catch (e) {
      developer.log('YOLO on-device initialization deferred: $e', name: 'LocalYoloVisionService');
      _isYoloReady = false;
      return false;
    }
  }

  @override
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    required LanguageProfile language,
  }) async {
    if (!_attemptedInit) {
      await initialize();
    }

    if (_isYoloReady && _yolo != null) {
      try {
        final rawResults = await _yolo!.predict(
          imageBytes,
          confidenceThreshold: 0.35,
          iouThreshold: 0.5,
        );

        final rawDetections = rawResults['detections'] as List? ?? [];
        final yoloResults = rawDetections
            .map((d) => YOLOResult.fromMap(d as Map<String, dynamic>))
            .where((r) => r.confidence >= 0.35)
            .toList();

        // Sort by confidence (highest confidence primary)
        yoloResults.sort((a, b) => b.confidence.compareTo(a.confidence));

        if (yoloResults.isNotEmpty) {
          final detectedObjects = <DetectedObject>[];

          for (int i = 0; i < yoloResults.length && i < 5; i++) {
            final res = yoloResults[i];
            final boxNorm = res.normalizedBox;
            final boxCoords = [
              (boxNorm.top * 1000).toInt().clamp(0, 1000),
              (boxNorm.left * 1000).toInt().clamp(0, 1000),
              (boxNorm.bottom * 1000).toInt().clamp(0, 1000),
              (boxNorm.right * 1000).toInt().clamp(0, 1000),
            ];

            final id = 'obj_0${i + 1}';
            final lexicon = LocalObjectLexicon.lookup(
              className: res.className,
              langCode: language.code,
            );

            if (lexicon != null) {
              detectedObjects.add(lexicon.toDetectedObject(id: id, box: boxCoords));
            } else {
              // Generic entry if class not yet in lexicon
              detectedObjects.add(
                DetectedObject(
                  id: id,
                  labelEn: res.className.capitalize(),
                  targetWord: res.className.capitalize(),
                  secondaryScript: res.className.toLowerCase(),
                  transliteration: res.className.toLowerCase(),
                  partOfSpeech: 'Noun',
                  difficultyLevel: 'A1',
                  box: boxCoords,
                ),
              );
            }
          }

          if (detectedObjects.isNotEmpty) {
            final primary = detectedObjects.first;
            return AnalysisResult(
              sessionId: 'mem_yolo_${DateTime.now().millisecondsSinceEpoch}',
              languageCode: language.code,
              primaryObjectId: primary.id,
              sceneDescription: 'Detected ${primary.labelEn} in view',
              detectedObjects: detectedObjects,
            );
          }
        }
      } catch (e) {
        developer.log('YOLO prediction error: $e, falling back to dynamic darkroom', name: 'LocalYoloVisionService');
      }
    }

    // High quality dynamic offline darkroom fallback
    return _fallbackService.analyze(imageBytes: imageBytes, language: language);
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
