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

/// Stitch "Memoria - Shake to Develop"
/// Studio worktable stage where captured latent photo develops out of dark chemical
/// emulsion fluid synchronized with accelerometer physical shakes and fallback timer.
class DevelopScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const DevelopScreen({super.key, required this.imagePath});

  @override
  ConsumerState<DevelopScreen> createState() => _DevelopScreenState();
}

class _DevelopScreenState extends ConsumerState<DevelopScreen> {
  StreamSubscription<UserAccelerometerEvent>? _sensorSub;
  Timer? _fallbackTimer;

  bool _isShaken = false;
  bool _isAiDone = false;
  AnalysisResult? _aiResult;
  String? _errorMessage;

  double _agitationLevel = 0.0;
  DateTime _lastShakeTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startAiAnalysis();
    _listenToShakeSensor();
    _startFallbackTimer();
  }

  void _startFallbackTimer() {
    // 4.5s fallback reveal timer per spec
    _fallbackTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted && !_isShaken) {
        setState(() {
          _isShaken = true;
          _agitationLevel = 1.0;
        });
        _checkAndProceed();
      }
    });
  }

  void _listenToShakeSensor() {
    _sensorSub = userAccelerometerEventStream().listen((event) {
      final now = DateTime.now();
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Threshold > 15 m/s² with 200ms debounce
      if (magnitude > 15.0 && now.difference(_lastShakeTime).inMilliseconds > 200) {
        _lastShakeTime = now;
        HapticFeedback.lightImpact();

        setState(() {
          _agitationLevel = (_agitationLevel + 0.25).clamp(0.0, 1.0);
          if (_agitationLevel >= 1.0) {
            _isShaken = true;
          }
        });

        if (_isShaken) {
          _checkAndProceed();
        }
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
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _simulateShake() {
    HapticFeedback.mediumImpact();
    setState(() {
      _agitationLevel = 1.0;
      _isShaken = true;
    });
    _checkAndProceed();
  }

  void _checkAndProceed() {
    if (_isShaken && _isAiDone && _aiResult != null && mounted) {
      HapticFeedback.heavyImpact();
      context.pushReplacement(
        '/editor',
        extra: {
          'imagePath': widget.imagePath,
          'analysisResult': _aiResult,
        },
      );
    }
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = ref.watch(selectedPolaroidFormatProvider);
    final aiMode = ref.watch(aiVisionModeProvider);

    return Scaffold(
      backgroundColor: MemoriaTokens.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Darkroom Development',
          style: MemoriaTokens.headlineSm(),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              // 1. Studio Worktable Stage with Ambient Light Spill
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Ambient light spill glows
                    Positioned(
                      top: -16,
                      left: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MemoriaTokens.primaryContainer.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      right: -16,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MemoriaTokens.secondaryContainer.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                    // The Developing Polaroid Physical Card
                    Transform.rotate(
                      angle: -0.018,
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
                                        duration: const Duration(milliseconds: 300),
                                        opacity: (0.15 + (0.85 * _agitationLevel)).clamp(0.0, 1.0),
                                        child: Image.file(
                                          File(widget.imagePath),
                                          fit: BoxFit.cover,
                                        ),
                                      ),

                                    // Swirling Chemical Emulsion Veil
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: (1.0 - _agitationLevel * 0.85).clamp(0.0, 1.0),
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
                                            _isShaken ? 'Fixing Image...' : 'Shake Gently...',
                                            style: MemoriaTokens.handwrittenChin(
                                              fontSize: 22,
                                              color: Colors.white54,
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
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 2. Shake Ritual Interaction Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MemoriaTokens.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(MemoriaTokens.radiusLg),
                  border: Border.all(color: MemoriaTokens.polaroidBorder),
                  boxShadow: MemoriaTokens.shadowLevel1,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.vibration, color: MemoriaTokens.primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Chemical Agitation', style: MemoriaTokens.labelLg()),
                          ],
                        ),
                        Text(
                          '${(_agitationLevel * 100).toInt()}%',
                          style: MemoriaTokens.labelLg(color: MemoriaTokens.primaryDark),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                      child: LinearProgressIndicator(
                        value: _agitationLevel,
                        backgroundColor: MemoriaTokens.surfaceContainer,
                        valueColor: const AlwaysStoppedAnimation<Color>(MemoriaTokens.primary),
                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // AI Engine State
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: aiMode == AiVisionMode.cloudMistral
                                ? MemoriaTokens.primaryContainer
                                : MemoriaTokens.secondaryContainer,
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(aiMode == AiVisionMode.cloudMistral ? '☁️' : '⚡',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 5),
                              Text(
                                _isAiDone
                                    ? 'Vocabulary Ready ✓'
                                    : (aiMode == AiVisionMode.cloudMistral
                                        ? 'Mistral VLM parsing...'
                                        : 'ML Kit analyzing...'),
                                style: MemoriaTokens.labelSm(
                                  color: aiMode == AiVisionMode.cloudMistral
                                      ? MemoriaTokens.primaryDark
                                      : MemoriaTokens.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Error: $_errorMessage',
                  style: MemoriaTokens.bodySm(color: MemoriaTokens.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Tester Shake Simulator Button
              OutlinedButton.icon(
                onPressed: _simulateShake,
                icon: const Icon(Icons.touch_app, size: 16),
                label: const Text('Simulate Shake (Tester Shortcut)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
