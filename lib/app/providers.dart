import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/languages/language_profile.dart';
import '../data/repositories/polaroid_repository.dart';
import '../data/services/local_gemma_vision_service.dart';
import '../data/services/mistral_vision_service.dart';
import '../domain/models/polaroid.dart';
import '../domain/services/vision_service.dart';

enum AiVisionMode {
  cloudMistral,
  localGemma,
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
  // Default to cloudMistral if key is available, else localGemma
  final apiKey = _getMistralApiKey();
  return apiKey.trim().isNotEmpty ? AiVisionMode.cloudMistral : AiVisionMode.localGemma;
});

final visionServiceProvider = Provider<VisionService>((ref) {
  final mode = ref.watch(aiVisionModeProvider);
  if (mode == AiVisionMode.localGemma) {
    return LocalGemmaVisionService();
  }

  final apiKey = _getMistralApiKey();
  if (apiKey.trim().isNotEmpty) {
    return MistralVisionService(apiKey: apiKey);
  }
  return LocalGemmaVisionService();
});

final polaroidRepositoryProvider = Provider<PolaroidRepository>((ref) {
  return PolaroidRepository();
});

final activeLanguageProvider = StateProvider<LanguageProfile>((ref) {
  // Default to Japanese (Tier 1 focus)
  return LanguageRegistry.japanese;
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
