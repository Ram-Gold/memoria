import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../app/providers.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../domain/models/analysis_result.dart';

/// Minimalist Polaroid Print & Shake Development Screen
/// Clean fullscreen light-mode stage where the Polaroid is printed out from above,
/// and develops as the user shakes the device physically or agitates via touch.
class DevelopScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const DevelopScreen({super.key, required this.imagePath});

  @override
  ConsumerState<DevelopScreen> createState() => _DevelopScreenState();
}

class _DevelopScreenState extends ConsumerState<DevelopScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _printController;
  late Animation<Offset> _printSlideAnimation;
  late Animation<double> _printFadeAnimation;

  StreamSubscription<UserAccelerometerEvent>? _sensorSub;
  Timer? _fallbackTimer;

  bool _isShaken = false;
  bool _isAiDone = false;
  bool _isTransitioning = false;
  AnalysisResult? _aiResult;

  double _agitationLevel = 0.0;
  DateTime _lastShakeTime = DateTime.now();
  Offset _touchDragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    _printController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _printSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _printController,
        curve: Curves.easeOutCubic,
      ),
    );

    _printFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _printController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Initial mechanical ejection haptic tick
    HapticFeedback.mediumImpact();
    _printController.forward();

    _startAiAnalysis();
    _listenToShakeSensor();
    _startFallbackTimer();
  }

  void _startFallbackTimer() {
    // 5.5s safety fallback timer so learner is never blocked
    _fallbackTimer = Timer(const Duration(milliseconds: 5500), () {
      if (mounted && !_isShaken) {
        _addAgitation(1.0);
      }
    });
  }

  void _addAgitation(double amount) {
    if (_isShaken) return;

    setState(() {
      _agitationLevel = (_agitationLevel + amount).clamp(0.0, 1.0);
      if (_agitationLevel >= 1.0) {
        _isShaken = true;
      }
    });

    if (_isShaken) {
      _checkAndProceed();
    }
  }

  void _listenToShakeSensor() {
    _sensorSub = userAccelerometerEventStream().listen((event) {
      final now = DateTime.now();
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Accelerometer shake threshold > 14 m/s² with 180ms debounce
      if (magnitude > 14.0 && now.difference(_lastShakeTime).inMilliseconds > 180) {
        _lastShakeTime = now;
        HapticFeedback.lightImpact();
        _addAgitation(0.25);
      }
    }, onError: (err) {
      debugPrint('Accelerometer not available: $err');
    });
  }

  Future<void> _startAiAnalysis() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final language = ref.read(activeLanguageProvider);
      final visionService = ref.read(visionServiceProvider);

      final result = await visionService.analyze(
        imageBytes: bytes,
        language: language,
      );

      // Augment result with RAG (Lexicon Ground Truth + Spaced Memory Recall)
      final ragService = ref.read(ragServiceProvider);
      final augmentedResult = await ragService.augment(
        rawResult: result,
        languageCode: language.code,
      );

      if (mounted) {
        setState(() {
          _isAiDone = true;
          _aiResult = augmentedResult;
        });
        _checkAndProceed();
      }
    } catch (e) {
      debugPrint('AI analysis error: $e');
      if (mounted) {
        setState(() {
          _isAiDone = true;
        });
        _checkAndProceed();
      }
    }
  }

  void _checkAndProceed() {
    if (_isShaken && _isAiDone && _aiResult != null && !_isTransitioning && mounted) {
      _isTransitioning = true;
      // Satisfying double-pulse haptic vibration to celebrate developed photo
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 160), () {
        HapticFeedback.heavyImpact();
      });

      // Brief ~600ms pause so the user admires the developed photograph before transition
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) {
          context.pushReplacement(
            '/editor',
            extra: {
              'imagePath': widget.imagePath,
              'analysisResult': _aiResult,
            },
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _printController.dispose();
    _sensorSub?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = ref.watch(selectedPolaroidFormatProvider);

    return Scaffold(
      backgroundColor: MemoriaTokens.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SlideTransition(
            position: _printSlideAnimation,
            child: FadeTransition(
              opacity: _printFadeAnimation,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final dist = details.delta.distance;
                  if (dist > 5.0) {
                    _addAgitation(0.035);
                    HapticFeedback.selectionClick();
                  }
                  setState(() {
                    _touchDragOffset = Offset(
                      (_touchDragOffset.dx + details.delta.dx * 0.35).clamp(-30.0, 30.0),
                      (_touchDragOffset.dy + details.delta.dy * 0.35).clamp(-30.0, 30.0),
                    );
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _touchDragOffset = Offset.zero;
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _touchDragOffset = Offset.zero;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(
                    _touchDragOffset.dx,
                    _touchDragOffset.dy,
                    0,
                  )..rotateZ(-0.015 + (_touchDragOffset.dx * 0.001)),
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: MemoriaTokens.polaroidCard,
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                      border: Border.all(color: MemoriaTokens.polaroidBorder, width: 1),
                      boxShadow: MemoriaTokens.shadowPolaroid,
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Developing Emulsion Window
                        AspectRatio(
                          aspectRatio: format.ratio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: MemoriaTokens.emulsionDark,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Emerging Latent Photograph
                                if (File(widget.imagePath).existsSync())
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: (0.12 + (0.88 * _agitationLevel)).clamp(0.0, 1.0),
                                    child: Image.file(
                                      File(widget.imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                // Swirling Chemical Emulsion Veil
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: (1.0 - _agitationLevel * 0.95).clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment.center,
                                        radius: 0.9,
                                        colors: [
                                          const Color(0xFF2A231D).withValues(alpha: 0.92),
                                          const Color(0xFF18191C).withValues(alpha: 0.95),
                                          const Color(0xFF101114).withValues(alpha: 0.98),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _agitationLevel > 0.05
                                            ? (_agitationLevel >= 0.75 ? 'Almost there...' : 'Developing...')
                                            : 'Shake to develop...',
                                        style: MemoriaTokens.handwrittenChin(
                                          fontSize: 22,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Clean Authentic Polaroid Chin Margin
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
