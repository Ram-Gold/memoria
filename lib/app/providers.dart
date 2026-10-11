import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/ai/ai_settings_provider.dart';
import '../core/constants/ai_providers.dart';
import '../core/languages/language_profile.dart';
import '../core/rag/rag_service.dart';
import '../data/repositories/polaroid_repository.dart';
import '../data/services/gemini_vision_service.dart';
import '../data/services/local_gemma_vision_service.dart';
import '../data/services/local_mlkit_vision_service.dart';
import '../data/services/local_vlm_model_manager.dart';
import '../domain/models/detected_object.dart';
import '../domain/models/polaroid.dart';
import '../domain/models/polaroid_format.dart';
import '../domain/services/vision_service.dart';

export '../domain/models/polaroid_format.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);
final cameraFlashModeProvider = StateProvider<FlashMode>((ref) => FlashMode.auto);
final cameraAspectRatioProvider = StateProvider<String>((ref) => '1:1');

final selectedPolaroidFormatProvider = Provider<PolaroidFormat>((ref) {
  final ratioId = ref.watch(cameraAspectRatioProvider);
  return PolaroidFormat.fromId(ratioId);
});

// Backward compatibility alias for legacy call sites
typedef AiVisionMode = AiEngineMode;
final aiVisionModeProvider = Provider<AiEngineMode>((ref) {
  return ref.watch(aiEngineModeProvider);
});

final localMlKitVisionServiceProvider = Provider<LocalMlKitVisionService>((ref) {
  return LocalMlKitVisionService();
});

final localGemmaVisionServiceProvider = Provider<LocalGemmaVisionService>((ref) {
  return LocalGemmaVisionService();
});

final localVlmModelManagerProvider = ChangeNotifierProvider<LocalVlmModelManager>((ref) {
  final manager = LocalVlmModelManager();
  manager.initialize();
  return manager;
});

final visionServiceProvider = Provider<VisionService>((ref) {
  final mode = ref.watch(aiEngineModeProvider);
  if (mode == AiEngineMode.local) {
    // Dual-tier on-device vision AI (PaliGemma 3B VLM + high-speed ML Kit computer vision)
    return ref.watch(localGemmaVisionServiceProvider);
  }

  final selectedProvider = ref.watch(selectedCloudProviderProvider);
  final apiKeysNotifier = ref.watch(aiApiKeysProvider.notifier);
  final key = apiKeysNotifier.getKey(selectedProvider);

  return GeminiVisionService(apiKey: key);
});

final polaroidRepositoryProvider = Provider<PolaroidRepository>((ref) {
  return PolaroidRepository();
});

final activeLanguageProvider = StateProvider<LanguageProfile>((ref) {
  // Default to Japanese (Tier 1 focus)
  return LanguageRegistry.japanese;
});

/// Minimum confidence score threshold required for objects to appear in the UI
final confidenceThresholdProvider = StateProvider<double>((ref) {
  return DetectedObject.defaultConfidenceThreshold;
});

class PolaroidsNotifier extends StateNotifier<AsyncValue<List<Polaroid>>> {
  final PolaroidRepository _repository;

  PolaroidsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPolaroids();
  }

  Future<void> loadPolaroids() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repository.getAllPolaroids();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPolaroid(Polaroid polaroid) async {
    await _repository.savePolaroid(polaroid);
    await loadPolaroids();
  }

  Future<void> deletePolaroid(String id) async {
    await _repository.deletePolaroid(id);
    await loadPolaroids();
  }

  Future<void> toggleFavorite(String id, bool isFav) async {
    await _repository.toggleFavorite(id, isFav);
    await loadPolaroids();
  }

  Future<void> updatePolaroid(Polaroid polaroid) async {
    await _repository.savePolaroid(polaroid);
    await loadPolaroids();
  }
}

final polaroidsProvider = StateNotifierProvider<PolaroidsNotifier, AsyncValue<List<Polaroid>>>((ref) {
  final repo = ref.watch(polaroidRepositoryProvider);
  return PolaroidsNotifier(repo);
});

final ragServiceProvider = Provider<RagService>((ref) {
  final repo = ref.watch(polaroidRepositoryProvider);
  return RagService(repository: repo);
});

final scrapbookSearchQueryProvider = StateProvider<String>((ref) => '');

final scrapbookFilteredPolaroidsProvider = FutureProvider.autoDispose<List<Polaroid>>((ref) async {
  // Listen to polaroidsProvider to invalidate when items are added or deleted
  ref.watch(polaroidsProvider);
  final query = ref.watch(scrapbookSearchQueryProvider).trim();
  final repo = ref.watch(polaroidRepositoryProvider);
  if (query.isEmpty) {
    return repo.getAllPolaroids();
  }
  return repo.searchPolaroids(query);
});

