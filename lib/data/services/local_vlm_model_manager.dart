import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status model for the on-device VLM (PaliGemma) download process.
class VlmDownloadProgress {
  final bool isDownloading;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? error;
  final bool isCompleted;

  const VlmDownloadProgress({
    this.isDownloading = false,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.isCompleted = false,
  });

  String get formattedProgress => '${(progress * 100).toStringAsFixed(1)}%';

  String get formattedDownloadedMb {
    final mb = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
    if (totalBytes > 0) {
      final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB / $totalMb MB';
    }
    return '$mb MB';
  }
}

/// Singleton manager responsible for on-device Vision-Language Model weights lifecycle:
/// - Verifies presence of PaliGemma/LiteRT quantized models in local app storage.
/// - Streams on-demand download progress with resume/cancel support.
/// - Allows manual sideloading / importing of model files via system file picker.
/// - Manages storage footprint and deletion.
class LocalVlmModelManager extends ChangeNotifier {
  static final LocalVlmModelManager _instance = LocalVlmModelManager._internal();
  factory LocalVlmModelManager() => _instance;
  LocalVlmModelManager._internal();

  static const String _modelFileName = 'paligemma_3b_vision_quant.bin';
  static const String _prefCustomUrlKey = 'memoria_vlm_custom_url';
  static const String _prefHfTokenKey = 'memoria_vlm_hf_token';
  
  // Default direct link to quantized PaliGemma on HuggingFace / CDN
  static const String defaultModelUrl =
      'https://huggingface.co/google/paligemma-3b-pt-224/resolve/main/paligemma-3b-pt-224.tflite';

  http.Client? _activeClient;
  bool _isDownloading = false;
  double _progress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  bool _hasModel = false;
  int _modelFileSize = 0;
  String? _modelPath;

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  int get downloadedBytes => _downloadedBytes;
  int get totalBytes => _totalBytes;
  String? get errorMessage => _errorMessage;
  bool get hasModel => _hasModel;
  int get modelFileSize => _modelFileSize;
  String? get modelPath => _modelPath;

  VlmDownloadProgress get currentStatus => VlmDownloadProgress(
        isDownloading: _isDownloading,
        progress: _progress,
        downloadedBytes: _downloadedBytes,
        totalBytes: _totalBytes,
        error: _errorMessage,
        isCompleted: _hasModel,
      );

  String get formattedModelSize {
    if (_modelFileSize <= 0) return '0 MB';
    if (_modelFileSize >= 1024 * 1024 * 1024) {
      return '${(_modelFileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(_modelFileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Initialize and check existing model state
  Future<void> initialize() async {
    await checkModelAvailability();
  }

  /// Check whether model file already exists on device
  Future<bool> checkModelAvailability() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${docDir.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final file = File('${modelsDir.path}/$_modelFileName');
      final exists = await file.exists();
      if (exists) {
        final length = await file.length();
        if (length > 1000000) { // Valid model weight file (>1MB)
          _hasModel = true;
          _modelFileSize = length;
          _modelPath = file.path;
          notifyListeners();
          return true;
        }
      }

      _hasModel = false;
      _modelFileSize = 0;
      _modelPath = null;
      notifyListeners();
      return false;
    } catch (e) {
      developer.log('Error checking VLM model availability: $e', name: 'LocalVlmModelManager');
      _hasModel = false;
      notifyListeners();
      return false;
    }
  }

  /// Get active model download URL (custom if configured, otherwise default)
  Future<String> getDownloadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefCustomUrlKey) ?? defaultModelUrl;
  }

  /// Set custom model download URL
  Future<void> setCustomDownloadUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url.trim().isEmpty || url == defaultModelUrl) {
      await prefs.remove(_prefCustomUrlKey);
    } else {
      await prefs.setString(_prefCustomUrlKey, url.trim());
    }
    notifyListeners();
  }

  /// Get Hugging Face access token
  Future<String> getHfToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefHfTokenKey) ?? '';
  }

  /// Set Hugging Face access token
  Future<void> setHfToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.trim().isEmpty) {
      await prefs.remove(_prefHfTokenKey);
    } else {
      await prefs.setString(_prefHfTokenKey, token.trim());
    }
    notifyListeners();
  }

  /// Start downloading the model with stream progress
  Future<bool> startDownload({String? targetUrl}) async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _progress = 0.0;
    _downloadedBytes = 0;
    _totalBytes = 0;
    _errorMessage = null;
    notifyListeners();

    IOSink? sink;
    File? tempFile;

    try {
      final url = targetUrl ?? await getDownloadUrl();
      final hfToken = await getHfToken();
      final docDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${docDir.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      tempFile = File('${modelsDir.path}/$_modelFileName.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      _activeClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      if (hfToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $hfToken';
      }
      final response = await _activeClient!.send(request);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'HTTP 401 Unauthorized: This model repository is gated on Hugging Face. '
          'Please enter your free Hugging Face Access Token in the settings below, or download the model file in your browser and use the folder icon to import it.',
        );
      }

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Server returned HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      _totalBytes = response.contentLength ?? 0;
      sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        if (!_isDownloading) {
          // User canceled
          break;
        }
        sink.add(chunk);
        _downloadedBytes += chunk.length;
        if (_totalBytes > 0) {
          _progress = (_downloadedBytes / _totalBytes).clamp(0.0, 1.0);
        }
        notifyListeners();
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (!_isDownloading) {
        // Canceled
        if (await tempFile.exists()) await tempFile.delete();
        notifyListeners();
        return false;
      }

      // Rename temp file to destination
      final finalFile = File('${modelsDir.path}/$_modelFileName');
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFile.path);

      _hasModel = true;
      _modelFileSize = await finalFile.length();
      _modelPath = finalFile.path;
      _isDownloading = false;
      _progress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Download failed: $e', name: 'LocalVlmModelManager');
      _errorMessage = 'Download error: $e';
      _isDownloading = false;
      if (sink != null) {
        try { await sink.close(); } catch (_) {}
      }
      if (tempFile != null && await tempFile.exists()) {
        try { await tempFile.delete(); } catch (_) {}
      }
      notifyListeners();
      return false;
    } finally {
      _activeClient?.close();
      _activeClient = null;
    }
  }

  /// Cancel any active in-flight download
  void cancelDownload() {
    if (!_isDownloading) return;
    _isDownloading = false;
    _activeClient?.close();
    _activeClient = null;
    _errorMessage = 'Download canceled by user';
    notifyListeners();
  }

  /// Import a locally downloaded model file (.bin / .task / .tflite) using file picker
  Future<bool> importModelFromFilePicker() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isEmpty || files.first.path == null) {
        return false;
      }

      final pickedPath = files.first.path!;
      final pickedFile = File(pickedPath);
      if (!await pickedFile.exists()) return false;

      final docDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${docDir.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final targetFile = File('${modelsDir.path}/$_modelFileName');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await pickedFile.copy(targetFile.path);

      _hasModel = true;
      _modelFileSize = await targetFile.length();
      _modelPath = targetFile.path;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Failed to import model file: $e', name: 'LocalVlmModelManager');
      _errorMessage = 'Import failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete on-device model file to reclaim storage space
  Future<void> deleteModel() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/models/$_modelFileName');
      if (await file.exists()) {
        await file.delete();
      }
      _hasModel = false;
      _modelFileSize = 0;
      _modelPath = null;
      notifyListeners();
    } catch (e) {
      developer.log('Failed to delete model: $e', name: 'LocalVlmModelManager');
    }
  }
}
