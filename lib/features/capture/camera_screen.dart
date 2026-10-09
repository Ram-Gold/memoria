import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import 'language_picker_sheet.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String _aspectRatio = '1:1';
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final controller = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller.initialize();
        if (mounted) {
          setState(() {
            _cameraController = controller;
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    try {
      setState(() => _isCapturing = true);
      String imagePath;

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile photo = await _cameraController!.takePicture();
        imagePath = photo.path;
      } else {
        // Fallback: Pick image from gallery if camera unavailable
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) {
          setState(() => _isCapturing = false);
          return;
        }
        imagePath = picked.path;
      }

      if (mounted) {
        context.push('/develop', extra: imagePath);
      }
    } catch (e) {
      debugPrint('Take picture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      context.push('/develop', extra: picked.path);
    }
  }

  void _cycleLanguage() {
    final active = ref.read(activeLanguageProvider);
    if (active.code == 'ja') {
      ref.read(activeLanguageProvider.notifier).state = LanguageRegistry.filipino;
    } else {
      ref.read(activeLanguageProvider.notifier).state = LanguageRegistry.japanese;
    }
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => const LanguagePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLanguage = ref.watch(activeLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoria Camera'),
        actions: [
          IconButton(
            tooltip: 'Flash: ${_flashMode.name.toUpperCase()}',
            icon: Icon(
              _flashMode == FlashMode.always
                  ? Icons.flash_on
                  : (_flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_off),
              color: _flashMode != FlashMode.off ? Colors.amber : Colors.grey,
            ),
            onPressed: () async {
              FlashMode nextMode;
              if (_flashMode == FlashMode.auto) {
                nextMode = FlashMode.always;
              } else if (_flashMode == FlashMode.always) {
                nextMode = FlashMode.off;
              } else {
                nextMode = FlashMode.auto;
              }

              setState(() {
                _flashMode = nextMode;
              });

              try {
                await _cameraController?.setFlashMode(nextMode);
              } catch (e) {
                debugPrint('Flash mode error: $e');
              }
            },
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (_aspectRatio == '1:1') {
                  _aspectRatio = '3:4';
                } else if (_aspectRatio == '3:4') {
                  _aspectRatio = '4:3';
                } else {
                  _aspectRatio = '1:1';
                }
              });
            },
            child: Text(_aspectRatio),
          ),
          IconButton(
            tooltip: ref.watch(aiVisionModeProvider) == AiVisionMode.localOnDevice
                ? 'AI Mode: Local On-Device AI (YOLO / Gemma)'
                : 'AI Mode: Mistral Cloud HD (Tap for Local)',
            icon: Icon(
              ref.watch(aiVisionModeProvider) == AiVisionMode.localOnDevice
                  ? Icons.memory
                  : Icons.cloud_done,
              color: ref.watch(aiVisionModeProvider) == AiVisionMode.localOnDevice
                  ? Colors.tealAccent
                  : Colors.amberAccent,
            ),
            onPressed: () {
              final current = ref.read(aiVisionModeProvider);
              final next = current == AiVisionMode.localOnDevice
                  ? AiVisionMode.cloudMistral
                  : AiVisionMode.localOnDevice;
              ref.read(aiVisionModeProvider.notifier).state = next;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  content: Text(
                    next == AiVisionMode.localOnDevice
                        ? 'Switched to Local On-Device AI (YOLO + Lexicon)'
                        : 'Switched to Mistral Cloud HD',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Language HUD Pill
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onLongPress: _showLanguagePicker,
                  child: ActionChip(
                    avatar: Text(activeLanguage.flagEmoji),
                    label: Text('${activeLanguage.displayName} (Tap to swap, Hold for all)'),
                    onPressed: _cycleLanguage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  tooltip: 'All Languages',
                  onPressed: _showLanguagePicker,
                ),
              ],
            ),
          ),

          // Viewfinder Container
          Expanded(
            child: Center(
              child: _isCameraInitialized && _cameraController != null
                  ? AspectRatio(
                      aspectRatio: _aspectRatio == '1:1'
                          ? 1.0
                          : (_aspectRatio == '3:4' ? 3 / 4 : 4 / 3),
                      child: ClipRect(
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  : Container(
                      width: 300,
                      height: 300,
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('Camera unavailable or simulator mode'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pick Photo from Gallery'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Shutter controls
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, size: 32),
                  onPressed: _pickFromGallery,
                  tooltip: 'Choose from Gallery',
                ),
                // Shutter button
                GestureDetector(
                  onTap: _isCapturing ? null : _takePicture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 4),
                      color: _isCapturing ? Colors.grey : Colors.redAccent,
                    ),
                    child: _isCapturing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.camera, color: Colors.white, size: 36),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, size: 32),
                  onPressed: () {
                    // Switch camera if available
                    if (_cameras.length > 1 && _cameraController != null) {
                      final newCam = _cameraController!.description == _cameras.first
                          ? _cameras.last
                          : _cameras.first;
                      _cameraController?.dispose();
                      _cameraController = CameraController(
                        newCam,
                        ResolutionPreset.high,
                        enableAudio: false,
                      );
                      _cameraController!.initialize().then((_) async {
                        try {
                          await _cameraController!.setFlashMode(_flashMode);
                        } catch (_) {}
                        if (mounted) setState(() {});
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
