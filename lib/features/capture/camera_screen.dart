import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../core/widgets/language_flag_icon.dart';
import 'language_picker_sheet.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isInitializingCamera = false;
  String? _cameraErrorMessage;
  Timer? _cameraRetryTimer;

  bool _isCapturing = false;
  bool _isFlashing = false;
  bool _hasCaptured = false;

  final GlobalKey _windowKey = GlobalKey();

  bool _controllersInitialized = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  late AnimationController _ejectController;
  late Animation<Offset> _ejectSlideAnimation;

  void _initAnimationControllers() {
    if (_controllersInitialized) return;
    _controllersInitialized = true;

    // Fast ease-out xenon flash burst animation
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _flashAnimation = Tween<double>(begin: 0.95, end: 0.0).animate(
      CurvedAnimation(
        parent: _flashController,
        curve: Curves.easeOutQuad,
      ),
    );
    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isFlashing = false);
      }
    });

    // Mechanical kick & ejection all the way off the bottom
    _ejectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _ejectSlideAnimation = TweenSequence<Offset>([
      // 1. Mechanical Kick upward (~12px bounce) as rollers engage the film
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.04),
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 18.0,
      ),
      // 2. Swift downward acceleration all the way off the screen
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, -0.04),
          end: const Offset(0, 1.85),
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 82.0,
      ),
    ]).animate(_ejectController);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimationControllers();
    _initializeCamera();
  }

  /// Disposes camera hardware cleanly to release native sensor back to OS.
  Future<void> _disposeCamera() async {
    _cameraRetryTimer?.cancel();
    _cameraRetryTimer = null;
    final controller = _cameraController;
    _cameraController = null;
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      }
    }
  }

  /// Guaranteed camera initialization with mutex guard, error recovery, and auto-retry.
  Future<void> _initializeCamera({bool isRetry = false}) async {
    if (_isInitializingCamera) return;

    // If controller is already initialized and healthy, keep it active
    if (!isRetry &&
        _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.hasError) {
      if (!_isCameraInitialized && mounted) {
        setState(() => _isCameraInitialized = true);
      }
      return;
    }

    _isInitializingCamera = true;
    _cameraRetryTimer?.cancel();

    try {
      // Cleanly tear down any stale controller first
      if (_cameraController != null) {
        try {
          await _cameraController!.dispose();
        } catch (_) {}
        _cameraController = null;
      }

      _cameras = await availableCameras();
      if (!mounted) return;

      if (_cameras.isEmpty) {
        setState(() {
          _isCameraInitialized = false;
          _cameraErrorMessage = 'No camera hardware found on this device.';
        });
        return;
      }

      final controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Listen for runtime camera errors (e.g. OS revocation, power save interrupt)
      controller.addListener(() {
        if (mounted && controller.value.hasError) {
          debugPrint('Runtime camera error: ${controller.value.errorDescription}');
          _ensureCameraActive();
        }
      });

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Restore active flash mode if configured
      final flashMode = ref.read(cameraFlashModeProvider);
      try {
        await controller.setFlashMode(flashMode);
      } catch (_) {}

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _cameraErrorMessage = null;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraErrorMessage = 'Camera standby ($e)';
        });

        // Auto-retry once after 1000ms if hardware was briefly busy
        if (!isRetry) {
          _cameraRetryTimer = Timer(const Duration(milliseconds: 1000), () {
            if (mounted && ref.read(navigationIndexProvider) == 0) {
              _initializeCamera(isRetry: true);
            }
          });
        }
      }
    } finally {
      _isInitializingCamera = false;
    }
  }

  /// Verifies that the camera is alive whenever this screen is presented.
  void _ensureCameraActive() {
    if (!mounted) return;
    final isPresented = ref.read(navigationIndexProvider) == 0;
    if (!isPresented) return;

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.hasError) {
      _initializeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Free camera hardware back to the OS when app is minimized or phone locked
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // When resuming, wake camera only if camera tab is actively selected
      if (ref.read(navigationIndexProvider) == 0) {
        _ensureCameraActive();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraRetryTimer?.cancel();
    _isCameraInitialized = false;
    _cameraController?.dispose();
    _cameraController = null;
    if (_controllersInitialized) {
      _flashController.dispose();
      _ejectController.dispose();
    }
    super.dispose();
  }



  Future<String> _cropToAperture({
    required String sourcePath,
    required Rect apertureOnScreen,
    required Size screenSize,
  }) async {
    try {
      final croppedPath = await compute(_cropImageTask, _CropParams(
        sourcePath: sourcePath,
        left: apertureOnScreen.left,
        top: apertureOnScreen.top,
        width: apertureOnScreen.width,
        height: apertureOnScreen.height,
        screenWidth: screenSize.width,
        screenHeight: screenSize.height,
      ));

      // Invalidate image cache so consecutive photos are never stale
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      return croppedPath;
    } catch (e) {
      debugPrint('Error cropping image to polaroid window: $e');
      return sourcePath;
    }
  }

  void _resetCaptureState() {
    if (!mounted) return;
    _ejectController.reset();
    setState(() {
      _isCapturing = false;
      _hasCaptured = false;
      _isFlashing = false;
    });
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    // Ensure camera is active and ready before capture
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _ensureCameraActive();
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
        _hasCaptured = true; // Turn window into dark emulsion with "Shake to develop..."
      });
      HapticFeedback.heavyImpact();

      // Measure exact aperture rectangle on screen in global coordinates BEFORE animation begins
      final box = _windowKey.currentContext?.findRenderObject() as RenderBox?;
      final screenSize = MediaQuery.of(context).size;
      final Rect apertureOnScreen;
      if (box != null && box.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero);
        final bottomRight = box.localToGlobal(Offset(box.size.width, box.size.height));
        apertureOnScreen = Rect.fromPoints(topLeft, bottomRight);
      } else {
        final format = ref.read(selectedPolaroidFormatProvider);
        final apertureW = 286.0;
        final apertureH = 286.0 / format.ratio;
        final left = (screenSize.width - apertureW) / 2.0;
        final top = (screenSize.height - apertureH) / 2.0 - 20.0;
        apertureOnScreen = Rect.fromLTWH(left, top, apertureW, apertureH);
      }

      // Synchronize xenon screen burst: Trigger when exposure begins
      setState(() => _isFlashing = true);
      _flashController.forward(from: 0.0);

      // Start capture immediately
      final captureFuture = _cameraController!.takePicture();

      // Trigger mechanical ejection animation concurrently with hardware exposure
      final ejectionFuture = _ejectController.forward(from: 0.0);

      final XFile photo = await captureFuture;
      final String rawPath = photo.path;

      // Run image decoding and cropping in background isolate concurrently
      final cropFuture = _cropToAperture(
        sourcePath: rawPath,
        apertureOnScreen: apertureOnScreen,
        screenSize: screenSize,
      );

      // Wait for both mechanical ejection and cropping to finish
      await ejectionFuture;
      final String imagePath = await cropFuture;

      if (mounted) {
        // Hand off seamlessly to the develop screen with zero UI hitch
        final pushFuture = context.push('/develop', extra: imagePath);

        // Instant Clean Reset behind the transition:
        // As soon as the develop screen covers the camera, reset so camera is instantly fresh on return
        Future.delayed(const Duration(milliseconds: 260), () {
          _resetCaptureState();
        });

        await pushFuture;
      }
    } catch (e) {
      debugPrint('Take picture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture error: $e')),
        );
      }
    } finally {
      // Guaranteed clean reset so 2nd photo is never blocked or stuck
      _resetCaptureState();
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
    final all = LanguageRegistry.presets;
    final currentIndex = all.indexWhere((l) => l.code == active.code);
    final nextIndex = (currentIndex + 1) % all.length;
    ref.read(activeLanguageProvider.notifier).state = all[nextIndex];
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

  Widget _buildUnstretchedCameraPreview(BuildContext context) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final previewSize = controller.value.previewSize;
    final double previewWidth;
    final double previewHeight;

    if (previewSize != null) {
      previewWidth = isLandscape ? previewSize.width : previewSize.height;
      previewHeight = isLandscape ? previewSize.height : previewSize.width;
    } else {
      final ratio = controller.value.aspectRatio;
      previewWidth = 1000.0;
      previewHeight = isLandscape ? (1000.0 / ratio) : (1000.0 * ratio);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewWidth,
          height: previewHeight,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _initAnimationControllers();

    final currentIndex = ref.watch(navigationIndexProvider);
    final isPresented = currentIndex == 0;

    // Guaranteed presentation check: If on camera tab and camera is inactive or has error, awaken post-frame
    if (isPresented &&
        !_isInitializingCamera &&
        (_cameraController == null ||
            !_cameraController!.value.isInitialized ||
            _cameraController!.value.hasError)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureCameraActive();
      });
    }

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

    ref.listen<int>(navigationIndexProvider, (previous, next) {
      if (next == 0) {
        _resetCaptureState();
        _ensureCameraActive();
      } else if (previous == 0) {
        // Free physical camera sensor while browsing Scrapbook or Calendar to save battery & thermals
        _disposeCamera();
      }
    });

    final latestPolaroid = polaroidsAsync.valueOrNull?.isNotEmpty == true
        ? polaroidsAsync.valueOrNull!.first
        : null;
    final totalCount = polaroidsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fullscreen Live Camera Preview (Bottom Layer)
          Positioned.fill(
            child: _isCameraInitialized &&
                    _cameraController != null &&
                    _cameraController!.value.isInitialized
                ? _buildUnstretchedCameraPreview(context)
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: _cameraErrorMessage != null
                          ? GestureDetector(
                              onTap: () => _initializeCamera(isRetry: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.refreshCw,
                                      color: MemoriaTokens.primary,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Camera standby',
                                      style: MemoriaTokens.headlineSm(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap anywhere to wake viewfinder',
                                      style: MemoriaTokens.bodySm(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const CircularProgressIndicator(
                              color: Colors.white24,
                            ),
                    ),
                  ),
          ),



          // 3. Fast Ease-Out Xenon Flash Burst (Only rendered when flashing)
          if (_isFlashing)
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: _flashAnimation.value),
                    ),
                  ),
                );
              },
            ),

          // 4. Main Viewfinder Content
          SafeArea(
            child: Column(
              children: [
                // Top Rangefinder HUD Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flash Toggle
                      GestureDetector(
                        onTap: _cycleFlashMode,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              switch (flashMode) {
                                FlashMode.auto => LucideIcons.zap,
                                FlashMode.always => LucideIcons.zap,
                                FlashMode.off => LucideIcons.zapOff,
                                _ => LucideIcons.zap,
                              },
                              size: 24,
                              color: flashMode == FlashMode.off
                                  ? Colors.white38
                                  : const Color(0xFFFFB597),
                            ),
                          ),
                        ),
                      ),

                      // AI Mode Toggle
                      GestureDetector(
                        onTap: _toggleAiMode,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              aiMode == AiVisionMode.cloudMistral
                                  ? LucideIcons.cloud
                                  : LucideIcons.cpu,
                              size: 22,
                              color: const Color(0xFFFFB597),
                            ),
                          ),
                        ),
                      ),

                      // Language Selector
                      GestureDetector(
                        onTap: _cycleLanguage,
                        onLongPress: _showLanguagePicker,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: LanguageFlagIcon(
                              language: activeLanguage,
                              width: 26,
                              borderRadius: 4.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Physical Polaroid Frame IS the Camera HUD Viewfinder!
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: SlideTransition(
                        position: _ejectSlideAnimation,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // The Hollow Polaroid Card
                              SizedBox(
                                width: 310,
                                height: 12 + (286 / format.ratio) + 52,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // 1. The Physical Card Body with Aperture Cutout Hole
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: PolaroidCardHollowPainter(
                                          apertureRect: Rect.fromLTWH(
                                            12,
                                            12,
                                            286,
                                            286 / format.ratio,
                                          ),
                                          cardColor: MemoriaTokens.polaroidCard,
                                          borderRadius: 6.0,
                                        ),
                                      ),
                                    ),

                                    // 2. The Aperture Window
                                    Positioned(
                                      left: 12,
                                      top: 12,
                                      width: 286,
                                      height: 286 / format.ratio,
                                      child: Container(
                                        key: _windowKey,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(3),
                                          border: Border.all(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            width: 1,
                                          ),
                                        ),
                                        child: _hasCaptured
                                            // Output upon clicking shutter: black blank image with "Shake to develop..."
                                            ? Container(
                                                decoration: BoxDecoration(
                                                  color: MemoriaTokens.emulsionDark,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Shake to develop...',
                                                    style: MemoriaTokens.handwrittenChin(
                                                      fontSize: 22,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            // Before shutter: crystal-clear see-through window
                                            : (!_isCameraInitialized
                                                ? const Center(
                                                    child: Icon(LucideIcons.camera, color: Colors.white24, size: 40),
                                                  )
                                                : const SizedBox.expand()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Authentic Polaroid Format Size Switcher Pills (1:1, 3:4, 4:3)
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
                                        ),
                                        child: Text(
                                          f.id,
                                          style: MemoriaTokens.labelSm(
                                            color: isSelected ? Colors.black87 : Colors.white70,
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
                ),

                // Bottom Tactile Shutter Dock
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Film Roll Counter & Gallery Preview Thumbnail
                      GestureDetector(
                        onTap: () {
                          ref.read(navigationIndexProvider.notifier).state = 1;
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                                color: Colors.black45,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: latestPolaroid != null && File(latestPolaroid.imagePath).existsSync()
                                  ? Image.file(
                                      File(latestPolaroid.imagePath),
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(LucideIcons.images, color: Colors.white70, size: 22),
                            ),
                            if (totalCount > 0)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: MemoriaTokens.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: Text(
                                    '$totalCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
                            border: Border.all(color: Colors.white, width: 3.5),
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
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isCapturing
                                  ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        color: Colors.black87,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : null,
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
                            LucideIcons.switchCamera,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 84),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a physical Polaroid card with a hollow aperture cutout hole
class PolaroidCardHollowPainter extends CustomPainter {
  final Rect apertureRect;
  final Color cardColor;
  final double borderRadius;

  PolaroidCardHollowPainter({
    required this.apertureRect,
    required this.cardColor,
    this.borderRadius = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final innerRRect = RRect.fromRectAndRadius(
      apertureRect,
      const Radius.circular(3.0),
    );

    // Difference path: Cuts out the aperture window completely!
    final cardPath = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outerRRect),
      Path()..addRRect(innerRRect),
    );

    // Physical card elevation shadow
    canvas.drawShadow(cardPath, const Color(0x99000000), 22.0, true);

    // Paint the paper card
    canvas.drawPath(cardPath, Paint()..color = cardColor);

    // Subtle edge highlight
    canvas.drawRRect(
      outerRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant PolaroidCardHollowPainter oldDelegate) {
    return oldDelegate.apertureRect != apertureRect ||
        oldDelegate.cardColor != cardColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Parameters for background image cropping compute task
class _CropParams {
  final String sourcePath;
  final double left;
  final double top;
  final double width;
  final double height;
  final double screenWidth;
  final double screenHeight;

  const _CropParams({
    required this.sourcePath,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.screenWidth,
    required this.screenHeight,
  });
}

/// Standalone top-level isolate task that performs image decoding, orientation baking,
/// and cropping off the UI thread to keep the 60fps viewfinder and animation completely fluid.
Future<String> _cropImageTask(_CropParams params) async {
  try {
    final file = File(params.sourcePath);
    final rawBytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) return params.sourcePath;

    // Bake EXIF orientation so pixels match visual screen orientation
    image = img.bakeOrientation(image);

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    // Camera preview on screen uses BoxFit.cover
    final scale = max(params.screenWidth / imgW, params.screenHeight / imgH);
    final renderedW = imgW * scale;
    final renderedH = imgH * scale;

    final offsetX = (renderedW - params.screenWidth) / 2.0;
    final offsetY = (renderedH - params.screenHeight) / 2.0;

    // Map screen aperture bounds to image coordinates accurately
    final cropX = ((params.left + offsetX) / scale).round().clamp(0, image.width - 1);
    final cropY = ((params.top + offsetY) / scale).round().clamp(0, image.height - 1);
    final cropW = (params.width / scale).round().clamp(1, image.width - cropX);
    final cropH = (params.height / scale).round().clamp(1, image.height - cropY);

    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final croppedPath = params.sourcePath.replaceAll('.jpg', '_cropped_$uniqueId.jpg');
    final croppedBytes = img.encodeJpg(cropped, quality: 92);
    await File(croppedPath).writeAsBytes(croppedBytes);

    return croppedPath;
  } catch (e) {
    debugPrint('Background cropping error: $e');
    return params.sourcePath;
  }
}


