import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      // Trigger realistic visual xenon flash burst
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switch (next) {
            FlashMode.auto => '⚡ Flash: Auto',
            FlashMode.always => '⚡ Flash: Always On',
            FlashMode.off => '🚫 Flash: Off',
            _ => '⚡ Flash: Auto',
          },
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cyclePolaroidFormat() {
    final current = ref.read(cameraAspectRatioProvider);
    final next = switch (current) {
      '1:1' => '3:4',
      '3:4' => '4:3',
      _ => '1:1',
    };
    ref.read(cameraAspectRatioProvider.notifier).state = next;
    HapticFeedback.selectionClick();
    final format = PolaroidFormat.fromId(next);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📷 Polaroid Size: ${format.filmType} (${format.displayName}) · ${format.dimensions}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPolaroidFormatSheet() {
    HapticFeedback.selectionClick();
    final currentFormat = ref.read(selectedPolaroidFormatProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Polaroid Size & Film Format',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose the physical aspect ratio and film dimensions for your print.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ...PolaroidFormat.values.map((f) {
                final isSelected = f == currentFormat;
                return ListTile(
                  leading: Icon(
                    switch (f) {
                      PolaroidFormat.square => Icons.crop_square,
                      PolaroidFormat.portrait => Icons.crop_portrait,
                      PolaroidFormat.landscape => Icons.crop_landscape,
                    },
                    color: isSelected ? const Color(0xFFE36528) : Colors.black87,
                    size: 28,
                  ),
                  title: Text(
                    '${f.filmType} (${f.displayName})',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text('Print dimensions: ${f.dimensions}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFFE36528))
                      : null,
                  onTap: () {
                    ref.read(cameraAspectRatioProvider.notifier).state = f.id;
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiVisionModeSheet() {
    HapticFeedback.selectionClick();
    final currentMode = ref.read(aiVisionModeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Vision Recognition Engine',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Memoria supports both Cloud Multimodal VLM and On-Device local intelligence.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFECE5),
                  child: Text('☁️', style: TextStyle(fontSize: 20)),
                ),
                title: const Text(
                  'Cloud AI (Mistral VLM)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('High contextual nuance, cultural vocabulary (Requires internet)'),
                trailing: currentMode == AiVisionMode.cloudMistral
                    ? const Icon(Icons.check_circle, color: Color(0xFFE36528))
                    : null,
                onTap: () {
                  ref.read(aiVisionModeProvider.notifier).state = AiVisionMode.cloudMistral;
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Text('⚡', style: TextStyle(fontSize: 20)),
                ),
                title: const Text(
                  'Local AI (On-Device ML Kit)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('100% offline, zero network latency (<50ms), private on-device'),
                trailing: currentMode == AiVisionMode.localOnDevice
                    ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
                    : null,
                onTap: () {
                  ref.read(aiVisionModeProvider.notifier).state = AiVisionMode.localOnDevice;
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLanguage = ref.watch(activeLanguageProvider);
    final format = ref.watch(selectedPolaroidFormatProvider);
    final flashMode = ref.watch(cameraFlashModeProvider);
    final aiMode = ref.watch(aiVisionModeProvider);

    ref.listen<FlashMode>(cameraFlashModeProvider, (previous, next) async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          await _cameraController!.setFlashMode(next);
        } catch (e) {
          debugPrint('Flash mode error: $e');
        }
      }
    });

    return Stack(
      children: [
        SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              // 1. Top Analog Control Bar: Flash Mode, Polaroid Size, AI Mode
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flash Mode Toggle Pill
                    InkWell(
                      onTap: _cycleFlashMode,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: flashMode == FlashMode.off
                              ? Colors.grey.shade200
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: flashMode == FlashMode.off
                                ? Colors.grey.shade400
                                : const Color(0xFFE36528),
                            width: 1.2,
                          ),
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
                              size: 17,
                              color: flashMode == FlashMode.off
                                  ? Colors.grey.shade700
                                  : const Color(0xFFE36528),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              switch (flashMode) {
                                FlashMode.auto => 'AUTO',
                                FlashMode.always => 'ON',
                                FlashMode.off => 'OFF',
                                _ => 'AUTO',
                              },
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: flashMode == FlashMode.off
                                    ? Colors.grey.shade700
                                    : const Color(0xFFE36528),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Polaroid Size / Film Format Badge & Switcher
                    InkWell(
                      onTap: _showPolaroidFormatSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black26, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              switch (format) {
                                PolaroidFormat.square => Icons.crop_square,
                                PolaroidFormat.portrait => Icons.crop_portrait,
                                PolaroidFormat.landscape => Icons.crop_landscape,
                              },
                              size: 16,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${format.displayName} [${format.id}]',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),

                    // AI Engine Mode Badge & Switcher
                    InkWell(
                      onTap: _showAiVisionModeSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: aiMode == AiVisionMode.cloudMistral
                              ? const Color(0xFFFFEFEA)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: aiMode == AiVisionMode.cloudMistral
                                ? const Color(0xFFE36528)
                                : const Color(0xFF2E7D32),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              aiMode == AiVisionMode.cloudMistral ? '☁️' : '⚡',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              aiMode == AiVisionMode.cloudMistral ? 'Cloud AI' : 'Local AI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: aiMode == AiVisionMode.cloudMistral
                                    ? const Color(0xFFD44B0F)
                                    : const Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Language HUD Pill (Responsive & flex-safe)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onLongPress: _showLanguagePicker,
                        child: ActionChip(
                          avatar: Text(activeLanguage.flagEmoji, style: const TextStyle(fontSize: 16)),
                          label: Text(
                            '${activeLanguage.displayName} (Tap to swap)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _cycleLanguage,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, size: 20),
                      tooltip: 'All Languages',
                      onPressed: _showLanguagePicker,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // 3. Polaroid Viewfinder with Physical Bezel & Format Tag
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Determine max width and height for Polaroid card
                      final double availW = constraints.maxWidth;
                      final double availH = constraints.maxHeight;

                      // Polaroid card geometry
                      const double cardPaddingHoriz = 10.0;
                      const double cardPaddingTop = 10.0;
                      const double cardChinHeight = 36.0;

                      // Available photo area inside card
                      final double maxPhotoW = availW - (cardPaddingHoriz * 2);
                      final double maxPhotoH = availH - cardPaddingTop - cardChinHeight - 10.0;

                      // Fit photo aspect ratio within available space
                      double photoW = maxPhotoW;
                      double photoH = photoW / format.ratio;

                      if (photoH > maxPhotoH) {
                        photoH = maxPhotoH;
                        photoW = photoH * format.ratio;
                      }

                      final double cardW = photoW + (cardPaddingHoriz * 2);
                      final double cardH = photoH + cardPaddingTop + cardChinHeight;

                      return Center(
                        child: Container(
                          width: cardW,
                          height: cardH,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFBF9), // Real Polaroid warm white paper
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x38000000),
                                blurRadius: 14,
                                spreadRadius: 1,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(
                            cardPaddingHoriz,
                            cardPaddingTop,
                            cardPaddingHoriz,
                            6,
                          ),
                          child: Column(
                            children: [
                              // Photo window
                              SizedBox(
                                width: photoW,
                                height: photoH,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: _isCameraInitialized &&
                                              _cameraController != null &&
                                              _cameraController!.value.isInitialized
                                          ? SizedBox.expand(
                                              child: FittedBox(
                                                fit: BoxFit.cover,
                                                child: SizedBox(
                                                  width: _cameraController!.value.previewSize?.height ?? photoW,
                                                  height: _cameraController!.value.previewSize?.width ?? photoH,
                                                  child: CameraPreview(_cameraController!),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFF1E1E1E),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.camera_alt_outlined, size: 40, color: Colors.white38),
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'Polaroid Viewfinder',
                                                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Tap Shutter or Gallery to Learn',
                                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),

                                    // Optical Viewfinder Reticle Corners
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Text('⌜', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 20)),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Text('⌝', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 20)),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Text('⌞', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 20)),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Text('⌟', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 20)),
                                    ),
                                  ],
                                ),
                              ),

                              // Polaroid Chin: Authentic size & film watermark
                              Expanded(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'MEMORIA • ${format.filmType.toUpperCase()} • ${format.dimensions}',
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.black.withValues(alpha: 0.42),
                                          fontSize: 9.5,
                                          letterSpacing: 1.1,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. Shutter Controls: Responsive, Tactile, and Non-Overflowing
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery Picker button
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined, size: 30),
                      onPressed: _pickFromGallery,
                      tooltip: 'Pick from Gallery',
                    ),

                    // Tactile Polaroid Shutter Button
                    GestureDetector(
                      onTap: _isCapturing ? null : _takePicture,
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1918),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFF523B),
                                  Color(0xFFE36528),
                                  Color(0xFFBA4713),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x30E36528),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: _isCapturing
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),

                    // Flash Mode or Camera Switch button
                    IconButton(
                      icon: Icon(
                        _cameras.length > 1 ? Icons.cameraswitch_outlined : Icons.flash_on_outlined,
                        size: 30,
                      ),
                      onPressed: () {
                        if (_cameras.length > 1 && _cameraController != null) {
                          final newCam = _cameraController!.description == _cameras.first
                              ? _cameras.last
                              : _cameras.first;
                          setState(() {
                            _isCameraInitialized = false;
                          });
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
                          }).catchError((_) {
                            if (mounted) {
                              setState(() {
                                _isCameraInitialized = false;
                              });
                            }
                          });
                        } else {
                          _cycleFlashMode();
                        }
                      },
                      tooltip: _cameras.length > 1 ? 'Switch Camera' : 'Toggle Flash',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 5. Visual Flash Burst Animation Overlay (Physical Xenon Flash Simulator)
        IgnorePointer(
          ignoring: true,
          child: AnimatedOpacity(
            opacity: _isFlashing ? 0.95 : 0.0,
            duration: Duration(milliseconds: _isFlashing ? 30 : 120),
            curve: Curves.easeOut,
            child: Container(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
