import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/languages/language_profile.dart';
import '../core/rag/rag_service.dart';
import '../data/repositories/polaroid_repository.dart';
import '../data/services/local_gemma_vision_service.dart';
import '../data/services/local_mlkit_vision_service.dart';
import '../data/services/mistral_vision_service.dart';
import '../domain/models/detected_object.dart';
import '../domain/models/polaroid.dart';
import '../domain/services/vision_service.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);
final cameraFlashModeProvider = StateProvider<FlashMode>((ref) => FlashMode.auto);
final cameraAspectRatioProvider = StateProvider<String>((ref) => '1:1');

enum PolaroidFormat {
  square(
    id: '1:1',
    ratio: 1.0,
    displayName: '1:1 Square',
    filmType: 'Polaroid 600',
    dimensions: '88 × 107 mm',
  ),
  portrait(
    id: '3:4',
    ratio: 3 / 4,
    displayName: '3:4 Portrait',
    filmType: 'Polaroid Go',
    dimensions: '54 × 67 mm',
  ),
  landscape(
    id: '4:3',
    ratio: 4 / 3,
    displayName: '4:3 Wide',
    filmType: 'Polaroid Wide',
    dimensions: '108 × 86 mm',
  );

  final String id;
  final double ratio;
  final String displayName;
  final String filmType;
  final String dimensions;

  const PolaroidFormat({
    required this.id,
    required this.ratio,
    required this.displayName,
    required this.filmType,
    required this.dimensions,
  });

  static PolaroidFormat fromId(String id) {
    return PolaroidFormat.values.firstWhere(
      (f) => f.id == id,
      orElse: () => PolaroidFormat.square,
    );
  }
}

final selectedPolaroidFormatProvider = Provider<PolaroidFormat>((ref) {
  final ratioId = ref.watch(cameraAspectRatioProvider);
  return PolaroidFormat.fromId(ratioId);
});

enum AiVisionMode {
  cloudMistral,
  localOnDevice,
}

String _getMistralApiKey() {
  try {
    if (dotenv.isInitialized) {
      return dotenv.env['MISTRAL_API_KEY'] ?? '';
    }
  } catch (_) {}
  return '';
}

final aiVisionModeProvider = StateProvider<AiVisionMode>((ref) {
  // Default to cloudMistral if key is available, else localOnDevice
  final apiKey = _getMistralApiKey();
  return apiKey.trim().isNotEmpty ? AiVisionMode.cloudMistral : AiVisionMode.localOnDevice;
});

final localMlKitVisionServiceProvider = Provider<LocalMlKitVisionService>((ref) {
  return LocalMlKitVisionService();
});

final localGemmaVisionServiceProvider = Provider<LocalGemmaVisionService>((ref) {
  return LocalGemmaVisionService();
});

final visionServiceProvider = Provider<VisionService>((ref) {
  final mode = ref.watch(aiVisionModeProvider);
  if (mode == AiVisionMode.localOnDevice) {
    // Highly accurate real-pixel on-device computer vision (<50ms, zero model downloads)
    return LocalMlKitVisionService();
  }

  final apiKey = _getMistralApiKey();
  if (apiKey.trim().isNotEmpty) {
    return MistralVisionService(apiKey: apiKey);
  }
  return LocalMlKitVisionService();
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

