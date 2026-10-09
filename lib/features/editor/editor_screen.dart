import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/providers.dart';
import '../../core/services/app_tts_service.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../core/widgets/rubber_stamp.dart';
import '../../core/widgets/washi_tape.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/models/polaroid.dart';

/// Stitch "Polaroid Reveal & Object Explorer"
/// Combines the physical Polaroid frame with interactive in-photo hotspots,
/// handwritten Caveat script chin, RAG memory recall, and object switcher.
class EditorScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final AnalysisResult analysisResult;

  const EditorScreen({
    super.key,
    required this.imagePath,
    required this.analysisResult,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late DetectedObject _selectedObject;
  final AppTtsService _ttsService = AppTtsService();
  bool _isSaving = false;
  bool _invertScriptOrder = false; // For Baybayin vs Latin toggle
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _selectedObject = widget.analysisResult.primaryObject ??
        (widget.analysisResult.detectedObjects.isNotEmpty
            ? widget.analysisResult.detectedObjects.first
            : const DetectedObject(
                id: 'default',
                labelEn: 'Item',
                targetWord: 'Word',
                box: [200, 200, 800, 800],
              ));
    _ttsService.init();
  }

  Future<void> _speak([DetectedObject? obj]) async {
    final target = obj ?? _selectedObject;
    final language = ref.read(activeLanguageProvider);

    final result = await _ttsService.speak(
      languageCode: language.code,
      targetWord: target.targetWord,
      secondaryScript: target.secondaryScript,
      transliteration: target.transliteration,
    );

    if (!result.success && mounted && result.isMissingVoicePack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${language.displayName} offline voice data missing. Download offline speech data in Android Settings > Google Text-to-Speech.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _savePolaroid() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final polId = const Uuid().v4();
      final language = ref.read(activeLanguageProvider);

      final threshold = ref.read(confidenceThresholdProvider);
      final confidentObjects = widget.analysisResult.detectedObjects
          .where((o) => o.isConfident(threshold))
          .toList();

      final polaroid = Polaroid(
        id: polId,
        imagePath: widget.imagePath,
        outputImagePath: widget.imagePath,
        languageCode: language.code,
        selectedObjectId: _selectedObject.id,
        selectedWord: _selectedObject.targetWord,
        secondaryScript: _selectedObject.secondaryScript,
        transliteration: _selectedObject.transliteration,
        partOfSpeech: _selectedObject.partOfSpeech,
        difficultyLevel: _selectedObject.difficultyLevel,
        createdAt: DateTime.now(),
        detectedObjects: confidentObjects,
        isFavorite: _isFavorite,
      );

      await ref.read(polaroidsProvider.notifier).addPolaroid(polaroid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Preserved in your Scrapbook!', style: MemoriaTokens.bodyMd(color: Colors.white)),
              ],
            ),
            backgroundColor: MemoriaTokens.secondary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate to Scrapbook tab on main navigation scaffold
        ref.read(navigationIndexProvider.notifier).state = 2;
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.read(activeLanguageProvider);
    final isFilipino = language.code == 'fil';
    final format = ref.watch(selectedPolaroidFormatProvider);
    final threshold = ref.watch(confidenceThresholdProvider);
    final confidentObjects = widget.analysisResult.detectedObjects
        .where((o) => o.isConfident(threshold))
        .toList();

    final line1 = _invertScriptOrder
        ? (_selectedObject.secondaryScript ?? _selectedObject.targetWord)
        : _selectedObject.targetWord;

    final line2 = _invertScriptOrder
        ? _selectedObject.targetWord
        : (_selectedObject.secondaryScript ?? '');

    return Scaffold(
      backgroundColor: MemoriaTokens.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Polaroid Reveal',
          style: MemoriaTokens.headlineSm(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Pronunciation TTS',
            onPressed: _speak,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _savePolaroid,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MemoriaTokens.primary),
                    )
                  : const Icon(Icons.check, size: 18, color: MemoriaTokens.primary),
              label: Text(
                'Preserve',
                style: MemoriaTokens.labelLg(color: MemoriaTokens.primary),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          children: [
            // 1. The Physical Polaroid Print with In-Photo Hotspots
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Transform.rotate(
                    angle: -0.015,
                    child: Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: MemoriaTokens.polaroidCard,
                        borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                        border: Border.all(color: MemoriaTokens.polaroidBorder, width: 1),
                        boxShadow: MemoriaTokens.shadowPolaroid,
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Photographic Aperture Window with Hotspot Layer
                          AspectRatio(
                            aspectRatio: format.ratio,
                            child: LayoutBuilder(
                              builder: (context, photoConstraints) {
                                final photoW = photoConstraints.maxWidth;
                                final photoH = photoConstraints.maxHeight;

                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      width: 0.8,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Image File
                                      File(widget.imagePath).existsSync()
                                          ? Image.file(File(widget.imagePath), fit: BoxFit.cover)
                                          : Container(color: MemoriaTokens.surfaceContainerHigh),

                                      // Ambient Film Grain Overlay
                                      Container(
                                        color: MemoriaTokens.primary.withValues(alpha: 0.04),
                                      ),

                                      // Interactive In-Photo Hotspots
                                      ...confidentObjects.map((obj) {
                                        final isSelected = obj.id == _selectedObject.id;

                                        // Compute normalized box center
                                        final normTop = ((obj.box[0] + obj.box[2]) / 2) / 1000.0;
                                        final normLeft = ((obj.box[1] + obj.box[3]) / 2) / 1000.0;

                                        final posX = (normLeft * photoW).clamp(20.0, photoW - 20.0);
                                        final posY = (normTop * photoH).clamp(20.0, photoH - 20.0);

                                        return Positioned(
                                          left: posX - 16,
                                          top: posY - 16,
                                          child: GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              setState(() => _selectedObject = obj);
                                              _speak(obj);
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (isSelected)
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: MemoriaTokens.primary.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                Container(
                                                  width: 22,
                                                  height: 22,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected
                                                        ? MemoriaTokens.primary
                                                        : Colors.white.withValues(alpha: 0.85),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Color(0x40000000),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : MemoriaTokens.secondary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),

                                      // Film Roll Tag
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.55),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Text(
                                            format.filmType.toUpperCase(),
                                            style: MemoriaTokens.telemetryMono(
                                              fontSize: 8,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Signature Polaroid Chin with Handwritten Calligraphy
                          Container(
                            constraints: const BoxConstraints(minHeight: 64),
                            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      line1,
                                      textAlign: TextAlign.center,
                                      style: MemoriaTokens.handwrittenChin(
                                        fontSize: 32,
                                        color: MemoriaTokens.onSurface,
                                      ),
                                    ),
                                    if (line2.isNotEmpty || _selectedObject.transliteration != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        line2.isNotEmpty
                                            ? '$line2 ${_selectedObject.transliteration != null ? "· ${_selectedObject.transliteration}" : ""}'
                                            : _selectedObject.transliteration ?? '',
                                        style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                                      ),
                                    ],
                                  ],
                                ),

                                // Rubber Heart Stamp
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: RubberStampWidget(
                                    isStamped: _isFavorite,
                                    onTap: () {
                                      setState(() => _isFavorite = !_isFavorite);
                                    },
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Washi Tape Header
                  const Positioned(
                    top: -10,
                    child: WashiTapeWidget(width: 88, height: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Script Order Switcher for Tagalog / Baybayin
            if (isFilipino) ...[
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _invertScriptOrder = !_invertScriptOrder);
                },
                icon: const Icon(Icons.swap_vert, size: 16),
                label: Text(_invertScriptOrder ? 'Baybayin First' : 'Latin First'),
              ),
              const SizedBox(height: 14),
            ],

            // 2. AI Scene Context Card
            if (widget.analysisResult.sceneDescription.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MemoriaTokens.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                  border: Border.all(color: MemoriaTokens.polaroidBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: MemoriaTokens.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '“${widget.analysisResult.sceneDescription}”',
                        style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. Spaced Memory Recall (RAG)
            if (widget.analysisResult.ragContext?.hasHistory == true) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9ED),
                  borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                  border: Border.all(color: const Color(0xFFFFD599)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.history_edu, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.analysisResult.ragContext!.recallHeadline ?? 'Spaced Memory Recall',
                            style: MemoriaTokens.labelLg(color: const Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'First captured: ${widget.analysisResult.ragContext!.history!.firstCapturedAt.toLocal().toString().split(" ").first} · Reinforces retention!',
                            style: MemoriaTokens.bodySm(color: const Color(0xFF78350F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 4. Pedagogical Collocation Card
            if (widget.analysisResult.ragContext?.recommendedCollocation != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MemoriaTokens.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                  border: Border.all(color: MemoriaTokens.polaroidBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book, color: MemoriaTokens.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COLLOCATION GROUND TRUTH',
                            style: MemoriaTokens.labelSm(color: MemoriaTokens.secondary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.analysisResult.ragContext!.recommendedCollocation!,
                            style: MemoriaTokens.headlineSm(color: MemoriaTokens.onSurface),
                          ),
                          if (widget.analysisResult.ragContext!.phraseTranslation != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.analysisResult.ragContext!.phraseTranslation!,
                              style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 5. Detected Objects Switcher Cards
            if (confidentObjects.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Switch Taught Object in Scene:',
                  style: MemoriaTokens.labelLg(),
                ),
              ),
              const SizedBox(height: 8),
              ...confidentObjects.map((obj) {
                final isSelected = obj.id == _selectedObject.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedObject = obj);
                    _speak(obj);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MemoriaTokens.primaryContainer
                          : MemoriaTokens.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                      border: Border.all(
                        color: isSelected ? MemoriaTokens.primary : MemoriaTokens.polaroidBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            color: isSelected ? MemoriaTokens.primaryDark : MemoriaTokens.outline,
                            size: 20,
                          ),
                          onPressed: () => _speak(obj),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${obj.targetWord} (${obj.labelEn})',
                                style: MemoriaTokens.labelLg(
                                  color: isSelected ? MemoriaTokens.primaryDark : MemoriaTokens.onSurface,
                                ),
                              ),
                              if (obj.transliteration != null || obj.secondaryScript != null)
                                Text(
                                  '${obj.secondaryScript ?? ""} · ${obj.transliteration ?? ""}',
                                  style: MemoriaTokens.bodySm(),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: MemoriaTokens.secondaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${obj.confidencePercentage}% confident',
                            style: MemoriaTokens.labelSm(color: MemoriaTokens.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // Big Preserve Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePolaroid,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(
                  _isSaving ? 'Preserving...' : 'Save to Scrapbook',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
