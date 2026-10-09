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

      if (mounted) {
        setState(() {
          _isAiDone = true;
          _aiResult = result;
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Undeveloped black Polaroid frame
              Container(
                width: 260,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.white24, blurRadius: 12),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 48),
                child: Container(
                  color: Color.lerp(Colors.black, Colors.grey[800], _agitationLevel),
                  child: Center(
                    child: Text(
                      _isShaken ? 'Developing...' : 'Shake Gently...',
                      style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Status indicators
              Text(
                'Agitation Level: ${(_agitationLevel * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                _isAiDone ? 'AI analysis completed ✓' : 'AI analyzing photo...',
                style: TextStyle(
                  color: _isAiDone ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],

              const SizedBox(height: 24),

              // Button to simulate shake for simulator / testing
              OutlinedButton.icon(
                onPressed: _simulateShake,
                icon: const Icon(Icons.vibration, color: Colors.white),
                label: const Text('Simulate Shake (Tester Shortcut)', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
