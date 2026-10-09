import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/theme/memoria_tokens.dart';
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
  bool _isFlashing = false;

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
          final flashMode = ref.read(cameraFlashModeProvider);
          try {
            await controller.setFlashMode(flashMode);
          } catch (_) {}
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
    if (controller == null) return;

    if (state == AppLifecycleState.inactive) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isCameraInitialized = false;
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  Future<void> _triggerFlashEffect() async {
    if (!mounted) return;
    setState(() => _isFlashing = true);
    await Future.delayed(const Duration(milliseconds: 140));
    if (mounted) {
      setState(() => _isFlashing = false);
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    try {
      setState(() => _isCapturing = true);
      HapticFeedback.heavyImpact();

      // Trigger realistic xenon flash burst
      _triggerFlashEffect();

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
      HapticFeedback.mediumImpact();
      context.push('/develop', extra: picked.path);
    }
  }

  void _cycleLanguage() {
    final active = ref.read(activeLanguageProvider);
    HapticFeedback.selectionClick();
    if (active.code == 'ja') {
      ref.read(activeLanguageProvider.notifier).state = LanguageRegistry.filipino;
    } else {
      ref.read(activeLanguageProvider.notifier).state = LanguageRegistry.japanese;
    }
  }

  void _showLanguagePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguagePickerSheet(),
    );
  }

  void _cycleFlashMode() {
    final current = ref.read(cameraFlashModeProvider);
    final next = switch (current) {
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
    ref.read(cameraFlashModeProvider.notifier).state = next;
    HapticFeedback.selectionClick();
  }

  void _selectPolaroidFormat(PolaroidFormat f) {
    ref.read(cameraAspectRatioProvider.notifier).state = f.id;
    HapticFeedback.selectionClick();
  }

  void _toggleAiMode() {
    final current = ref.read(aiVisionModeProvider);
    final next = current == AiVisionMode.cloudMistral
        ? AiVisionMode.localOnDevice
        : AiVisionMode.cloudMistral;
    ref.read(aiVisionModeProvider.notifier).state = next;
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final activeLanguage = ref.watch(activeLanguageProvider);
    final format = ref.watch(selectedPolaroidFormatProvider);
    final flashMode = ref.watch(cameraFlashModeProvider);
    final aiMode = ref.watch(aiVisionModeProvider);
    final polaroidsAsync = ref.watch(polaroidsProvider);

    ref.listen<FlashMode>(cameraFlashModeProvider, (previous, next) async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          await _cameraController!.setFlashMode(next);
        } catch (e) {
          debugPrint('Flash mode error: $e');
        }
      }
    });

    final latestPolaroid = polaroidsAsync.valueOrNull?.isNotEmpty == true
        ? polaroidsAsync.valueOrNull!.first
        : null;
    final totalCount = polaroidsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: MemoriaTokens.emulsionDark,
      body: Stack(
        children: [
          // Background Atmospheric Vignette
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Color(0xFF1E2024),
                    Color(0xFF101114),
                    Color(0xFF0A0B0D),
                  ],
                ),
              ),
            ),
          ),

          // Main Viewfinder Content
          SafeArea(
            child: Column(
              children: [
                // 1. Top Rangefinder HUD Capsule Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flash Toggle Pill
                      GestureDetector(
                        onTap: _cycleFlashMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                switch (flashMode) {
                                  FlashMode.auto => Icons.flash_auto,
                                  FlashMode.always => Icons.flash_on,
                                  FlashMode.off => Icons.flash_off,
                                  _ => Icons.flash_auto,
                                },
                                size: 16,
                                color: flashMode == FlashMode.off
                                    ? Colors.white38
                                    : const Color(0xFFFFB597),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                switch (flashMode) {
                                  FlashMode.auto => 'AUTO',
                                  FlashMode.always => 'ON',
                                  FlashMode.off => 'OFF',
                                  _ => 'AUTO',
                                },
                                style: MemoriaTokens.telemetryMono(
                                  fontSize: 10,
                                  color: flashMode == FlashMode.off
                                      ? Colors.white38
                                      : const Color(0xFFFFB597),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // AI Mode Toggle Pill
                      GestureDetector(
                        onTap: _toggleAiMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                            border: Border.all(
                              color: aiMode == AiVisionMode.cloudMistral
                                  ? MemoriaTokens.primary.withValues(alpha: 0.5)
                                  : Colors.green.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(aiMode == AiVisionMode.cloudMistral ? '☁️' : '⚡',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                aiMode == AiVisionMode.cloudMistral ? 'Mistral' : 'Local ML',
                                style: MemoriaTokens.labelSm(
                                  color: aiMode == AiVisionMode.cloudMistral
                                      ? const Color(0xFFFFB597)
                                      : const Color(0xFF81C784),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Language Selector Pill
                      GestureDetector(
                        onTap: _cycleLanguage,
                        onLongPress: _showLanguagePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(activeLanguage.flagEmoji, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                activeLanguage.code.toUpperCase(),
                                style: MemoriaTokens.labelSm(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. The Physical Polaroid Frame IS the Camera HUD Viewfinder!
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 310,
                              decoration: BoxDecoration(
                                color: MemoriaTokens.polaroidCard,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x8A000000),
                                    blurRadius: 36,
                                    spreadRadius: 2,
                                    offset: Offset(0, 14),
                                  ),
                                  BoxShadow(
                                    color: Color(0x40000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Live Camera Inside the Emulsion Window
                                  Container(
                                    width: 286,
                                    height: 286 / format.ratio,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (_isCameraInitialized && _cameraController != null)
                                          CameraPreview(_cameraController!)
                                        else
                                          Container(
                                            color: const Color(0xFF181A1D),
                                            child: const Center(
                                              child: Icon(Icons.camera_alt_outlined, color: Colors.white24, size: 40),
                                            ),
                                          ),

                                        // Subtle Optical Focus Reticle
                                        Center(
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: Center(
                                              child: Container(
                                                width: 4,
                                                height: 4,
                                                decoration: const BoxDecoration(
                                                  color: MemoriaTokens.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Film Emulsion Grain Scrim
                                        IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.15),
                                                  Colors.transparent,
                                                  Colors.black.withValues(alpha: 0.25),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Authentic Polaroid Chin Margin
                                  Container(
                                    height: 44,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'MEMORIA • ${format.filmType.toUpperCase()}',
                                            overflow: TextOverflow.ellipsis,
                                            style: MemoriaTokens.telemetryMono(
                                              fontSize: 8.5,
                                              color: Colors.black.withValues(alpha: 0.45),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          format.dimensions,
                                          style: MemoriaTokens.telemetryMono(
                                            fontSize: 8.5,
                                            color: Colors.black.withValues(alpha: 0.35),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 3. Authentic Polaroid Format Size Switcher Pills (1:1, 3:4, 4:3)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: PolaroidFormat.values.map((f) {
                                  final isSelected = f == format;
                                  return GestureDetector(
                                    onTap: () => _selectPolaroidFormat(f),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                                        boxShadow: isSelected
                                            ? [
                                                const BoxShadow(
                                                  color: Color(0x33000000),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        f.displayName,
                                        style: MemoriaTokens.labelSm(
                                          color: isSelected ? MemoriaTokens.onSurface : Colors.white60,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Analog Camera Trigger Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Recent Shot Thumbnail Button
                      GestureDetector(
                        onTap: () {
                          if (latestPolaroid != null) {
                            context.push('/polaroid/${latestPolaroid.id}', extra: latestPolaroid);
                          } else {
                            ref.read(navigationIndexProvider.notifier).state = 2;
                          }
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Transform.rotate(
                              angle: -0.06,
                              child: Container(
                                width: 50,
                                height: 56,
                                padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                                decoration: BoxDecoration(
                                  color: MemoriaTokens.polaroidCard,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x40000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: latestPolaroid != null && File(latestPolaroid.imagePath).existsSync()
                                      ? Image.file(File(latestPolaroid.imagePath), fit: BoxFit.cover)
                                      : const Icon(Icons.photo_library_outlined, size: 20, color: Colors.black38),
                                ),
                              ),
                            ),
                            if (totalCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: MemoriaTokens.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 1.2),
                                  ),
                                  child: Text(
                                    '$totalCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Tactile Instant Shutter Button
                      GestureDetector(
                        onTap: _isCapturing ? null : _takePicture,
                        child: Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Color(0xFFFF7A45),
                                  MemoriaTokens.primary,
                                  MemoriaTokens.primaryDark,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x59E36528),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isCapturing
                                  ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Lens Flip Button / Gallery fallback
                      GestureDetector(
                        onTap: () {
                          if (_cameras.length > 1 && _cameraController != null) {
                            final newCam = _cameraController!.description == _cameras.first
                                ? _cameras.last
                                : _cameras.first;
                            setState(() => _isCameraInitialized = false);
                            _cameraController?.dispose();
                            _cameraController = null;
                            final newController = CameraController(
                              newCam,
                              ResolutionPreset.high,
                              enableAudio: false,
                            );
                            newController.initialize().then((_) async {
                              try {
                                await newController.setFlashMode(ref.read(cameraFlashModeProvider));
                              } catch (_) {}
                              if (mounted) {
                                setState(() {
                                  _cameraController = newController;
                                  _isCameraInitialized = true;
                                });
                              }
                            });
                          } else {
                            _pickFromGallery();
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Xenon Flash Effect
          if (_isFlashing)
            Positioned.fill(
              child: Container(color: Colors.white.withValues(alpha: 0.95)),
            ),
        ],
      ),
    );
  }
}
