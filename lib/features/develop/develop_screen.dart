import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../app/providers.dart';
import '../../domain/models/analysis_result.dart';

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
      // Calculate magnitude
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${format.filmType} • ${format.dimensions}',
          style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.8),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Undeveloped black Polaroid frame with authentic format styling
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.white24, blurRadius: 16),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: format.ratio,
                        child: Container(
                          color: Color.lerp(Colors.black, Colors.grey[850], _agitationLevel),
                          child: Center(
                            child: Text(
                              _isShaken ? 'Developing...' : 'Shake Gently...',
                              style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'MEMORIA • ${format.filmType.toUpperCase()} • ${format.dimensions}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // AI Engine Mode & Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: aiMode == AiVisionMode.cloudMistral
                        ? const Color(0x28E36528)
                        : const Color(0x282E7D32),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: aiMode == AiVisionMode.cloudMistral
                          ? const Color(0xFFE36528)
                          : const Color(0xFF4CAF50),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(aiMode == AiVisionMode.cloudMistral ? '☁️' : '⚡', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        aiMode == AiVisionMode.cloudMistral
                            ? 'Cloud AI (Mistral VLM)'
                            : 'Local AI (On-Device ML Kit)',
                        style: TextStyle(
                          color: aiMode == AiVisionMode.cloudMistral
                              ? const Color(0xFFFF8A65)
                              : const Color(0xFF81C784),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Status indicators
                Text(
                  'Agitation Level: ${(_agitationLevel * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  _isAiDone
                      ? 'AI vocabulary recognition complete ✓'
                      : (aiMode == AiVisionMode.cloudMistral
                          ? 'Mistral VLM parsing scene...'
                          : 'Local ML Kit analyzing image...'),
                  style: TextStyle(
                    color: _isAiDone ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 20),

                // Button to simulate shake for simulator / testing
                OutlinedButton.icon(
                  onPressed: _simulateShake,
                  icon: const Icon(Icons.vibration, color: Colors.white, size: 18),
                  label: const Text('Simulate Shake (Tester Shortcut)', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
