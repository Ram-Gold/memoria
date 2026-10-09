import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/ai_providers.dart';

const String _prefKeyEngineMode = 'memoria_ai_engine_mode';
const String _prefKeySelectedCloudProvider = 'memoria_ai_selected_cloud_provider';
const String _prefKeyPrefixApiKey = 'memoria_ai_api_key_';

/// Notifier to manage AI engine mode (local vs cloud)
class AiEngineModeNotifier extends StateNotifier<AiEngineMode> {
  AiEngineModeNotifier() : super(AiEngineMode.local) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyEngineMode);
      if (saved != null) {
        state = saved == 'cloud' ? AiEngineMode.cloud : AiEngineMode.local;
      }
    } catch (e) {
      developer.log('Error loading AiEngineMode: $e', name: 'AiSettings');
    }
  }

  Future<void> setMode(AiEngineMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyEngineMode, mode == AiEngineMode.local ? 'local' : 'cloud');
    } catch (e) {
      developer.log('Error saving AiEngineMode: $e', name: 'AiSettings');
    }
  }
}

final aiEngineModeProvider = StateNotifierProvider<AiEngineModeNotifier, AiEngineMode>((ref) {
  return AiEngineModeNotifier();
});

/// Notifier to manage selected cloud provider
class SelectedCloudProviderNotifier extends StateNotifier<AiCloudProvider> {
  SelectedCloudProviderNotifier() : super(AiCloudProvider.mistral) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeySelectedCloudProvider);
      if (saved != null) {
        state = AiCloudProvider.fromId(saved);
      }
    } catch (e) {
      developer.log('Error loading SelectedCloudProvider: $e', name: 'AiSettings');
    }
  }

  Future<void> setProvider(AiCloudProvider provider) async {
    state = provider;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeySelectedCloudProvider, provider.id);
    } catch (e) {
      developer.log('Error saving SelectedCloudProvider: $e', name: 'AiSettings');
    }
  }
}

final selectedCloudProviderProvider =
    StateNotifierProvider<SelectedCloudProviderNotifier, AiCloudProvider>((ref) {
  return SelectedCloudProviderNotifier();
});

/// Map of provider ID -> API Key (persisted in SharedPreferences with .env fallback)
class AiApiKeysNotifier extends StateNotifier<Map<String, String>> {
  AiApiKeysNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final map = <String, String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final provider in AiCloudProvider.values) {
        final saved = prefs.getString('$_prefKeyPrefixApiKey${provider.id}');
        if (saved != null && saved.trim().isNotEmpty) {
          map[provider.id] = saved.trim();
        } else {
          // Fallback to .env if initialized
          try {
            if (dotenv.isInitialized) {
              final envVal = dotenv.env[provider.envKeyName] ?? '';
              if (envVal.trim().isNotEmpty) {
                map[provider.id] = envVal.trim();
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      developer.log('Error loading API keys: $e', name: 'AiSettings');
    }
    state = map;
  }

  Future<void> setKey(AiCloudProvider provider, String key) async {
    final updated = Map<String, String>.from(state);
    if (key.trim().isEmpty) {
      updated.remove(provider.id);
    } else {
      updated[provider.id] = key.trim();
    }
    state = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (key.trim().isEmpty) {
        await prefs.remove('$_prefKeyPrefixApiKey${provider.id}');
      } else {
        await prefs.setString('$_prefKeyPrefixApiKey${provider.id}', key.trim());
      }
    } catch (e) {
      developer.log('Error saving API key: $e', name: 'AiSettings');
    }
  }

  String getKey(AiCloudProvider provider) {
    final direct = state[provider.id];
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }
    try {
      if (dotenv.isInitialized) {
        return (dotenv.env[provider.envKeyName] ?? '').trim();
      }
    } catch (_) {}
    return '';
  }
}

final aiApiKeysProvider = StateNotifierProvider<AiApiKeysNotifier, Map<String, String>>((ref) {
  return AiApiKeysNotifier();
});
