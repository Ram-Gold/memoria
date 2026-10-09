import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../core/languages/language_profile.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/services/vision_service.dart';
import 'local_mlkit_vision_service.dart';
import 'local_vlm_model_manager.dart';

/// Service implementing Local On-Device Vision AI using Google Gemma / PaliGemma via flutter_gemma.
/// 
/// Designed with dual-tier offline resilience and graceful degradation:
/// 1. Checks if a local quantized weights file exists via [LocalVlmModelManager].
/// 2. If present and loaded, runs multimodal token inference through [FlutterGemma].
/// 3. If model weights are not yet downloaded to the device or inference fails, seamlessly
///    degrades to Tier 1 instant computer vision ([LocalMlKitVisionService]).
class LocalGemmaVisionService implements VisionService {
  final LocalMlKitVisionService _mlkitService = LocalMlKitVisionService();
  final LocalVlmModelManager _modelManager = LocalVlmModelManager();
  bool _isModelLoaded = false;
  InferenceModel? _activeModel;

  LocalGemmaVisionService();

  /// Check whether local model weights exist in the app's documents directory
  Future<bool> isModelAvailable() async {
    return _modelManager.checkModelAvailability();
  }

  /// Initialize the local Gemma / PaliGemma engine via flutter_gemma if weights are present
  Future<bool> initialize() async {
    final available = await isModelAvailable();
    if (available && _modelManager.modelPath != null) {
      try {
        final path = _modelManager.modelPath!;
        developer.log(
          'Configuring flutter_gemma model from $path (${_modelManager.formattedModelSize})',
          name: 'LocalGemmaVisionService',
        );

        await FlutterGemma.installModel(
          modelType: ModelType.general,
        ).fromFile(path).install();

        _activeModel = await FlutterGemma.getActiveModel(
          maxTokens: 512,
          supportImage: true,
        );

        _isModelLoaded = true;
        developer.log('flutter_gemma active model successfully ready', name: 'LocalGemmaVisionService');
        return true;
      } catch (e) {
        developer.log('Failed to load flutter_gemma model: $e', name: 'LocalGemmaVisionService');
        _isModelLoaded = false;
        _activeModel = null;
        return false;
      }
    }
    developer.log(
      'Local VLM weights not found, using Tier 1 instant computer vision',
      name: 'LocalGemmaVisionService',
    );
    return false;
  }

  @override
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    required LanguageProfile language,
  }) async {
    await _modelManager.checkModelAvailability();
    if (!_isModelLoaded && _modelManager.hasModel) {
      await initialize();
    }

    if (!_isModelLoaded || _activeModel == null) {
      developer.log(
        'flutter_gemma weights not loaded on device. Executing Tier 1 instant computer vision.',
        name: 'LocalGemmaVisionService',
      );
      return _mlkitService.analyze(imageBytes: imageBytes, language: language);
    }

    try {
      final prompt = '''
Task: Identify 1 to 3 tangible physical objects in this photograph.
Target Language: ${language.code} (${language.displayName}).
${language.promptInstructions}

Return strict JSON only:
{
  "session_id": "mem_local_${DateTime.now().millisecondsSinceEpoch}",
  "language_code": "${language.code}",
  "primary_object_id": "obj_01",
  "scene_description": "concise scene context",
  "detected_objects": [
    {
      "id": "obj_01",
      "label_en": "object name in English",
      "target_word": "word in native script",
      "secondary_script": "phonetic reading",
      "transliteration": "pronunciation",
      "part_of_speech": "Noun",
      "difficulty_level": "A1 or N5",
      "confidence": 0.95,
      "box_2d": [150, 150, 850, 850]
    }
  ]
}
''';

      developer.log('Executing flutter_gemma multimodal inference', name: 'LocalGemmaVisionService');

      final session = await _activeModel!.createSession(
        enableVisionModality: true,
      );
      await session.addQueryChunk(
        Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        ),
      );
      final responseText = await session.getResponse();
      await session.close();

      final cleanJson = _extractJson(responseText);
      if (cleanJson != null) {
        final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
        return AnalysisResult.fromJson(parsed);
      }

      developer.log('Could not parse valid JSON from flutter_gemma output, falling back to ML Kit', name: 'LocalGemmaVisionService');
      return _mlkitService.analyze(imageBytes: imageBytes, language: language);
    } catch (e) {
      developer.log('flutter_gemma inference error: $e, falling back to ML Kit', name: 'LocalGemmaVisionService');
      return _mlkitService.analyze(imageBytes: imageBytes, language: language);
    }
  }

  String? _extractJson(String raw) {
    try {
      final startIndex = raw.indexOf('{');
      final endIndex = raw.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        return raw.substring(startIndex, endIndex + 1);
      }
    } catch (_) {}
    return null;
  }
}
