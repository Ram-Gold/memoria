import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/providers.dart';
import '../../core/services/app_tts_service.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/models/polaroid.dart';

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
                box: [0, 0, 1000, 1000],
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
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }

  Future<void> _savePolaroid() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

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
        outputImagePath: widget.imagePath, // In future, RepaintBoundary export PNG
        languageCode: language.code,
        selectedObjectId: _selectedObject.id,
        selectedWord: _selectedObject.targetWord,
        secondaryScript: _selectedObject.secondaryScript,
        transliteration: _selectedObject.transliteration,
        partOfSpeech: _selectedObject.partOfSpeech,
        difficultyLevel: _selectedObject.difficultyLevel,
        createdAt: DateTime.now(),
        detectedObjects: confidentObjects,
      );

      await ref.read(polaroidsProvider.notifier).addPolaroid(polaroid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Scrapbook!')),
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

    final line1 = _invertScriptOrder
        ? (_selectedObject.secondaryScript ?? _selectedObject.targetWord)
        : _selectedObject.targetWord;

    final line2 = _invertScriptOrder
        ? _selectedObject.targetWord
        : (_selectedObject.secondaryScript ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polaroid Reveal & Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Pronunciation TTS',
            onPressed: _speak,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: 'Save Polaroid',
            onPressed: _isSaving ? null : _savePolaroid,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Scene Description
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[200],
              child: Text(
                'AI Scene: "${widget.analysisResult.sceneDescription}"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),

            // RAG Spaced Memory Recall Card
            if (widget.analysisResult.ragContext?.hasHistory == true) ...[
              Card(
                color: Colors.amber[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.history_edu, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.analysisResult.ragContext!.recallHeadline ?? 'Spaced Memory Recall',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'First captured: ${widget.analysisResult.ragContext!.history!.firstCapturedAt.toLocal().toString().split(" ").first} · Reinforces spaced learning retention!',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // RAG Pedagogical Collocation Card
            if (widget.analysisResult.ragContext?.recommendedCollocation != null) ...[
              Card(
                color: Colors.blueGrey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.blueGrey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.menu_book, color: Colors.blueGrey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Collocation Ground Truth (Dictionary RAG):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.analysisResult.ragContext!.recommendedCollocation!,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            if (widget.analysisResult.ragContext!.phraseTranslation != null)
                              Text(
                                widget.analysisResult.ragContext!.phraseTranslation!,
                                style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],


            // Polaroid Card Frame
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              child: Column(
                children: [
                  // Polaroid Format and AI Engine Header Bar
                  Builder(
                    builder: (context) {
                      final format = ref.watch(selectedPolaroidFormatProvider);
                      final aiMode = ref.watch(aiVisionModeProvider);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${format.filmType.toUpperCase()} • ${format.dimensions}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: aiMode == AiVisionMode.cloudMistral
                                    ? const Color(0x1FE36528)
                                    : const Color(0x1F2E7D32),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                aiMode == AiVisionMode.cloudMistral ? '☁️ Mistral VLM' : '⚡ Local ML Kit',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: aiMode == AiVisionMode.cloudMistral
                                      ? const Color(0xFFD44B0F)
                                      : const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Photo fitted to selected Polaroid format
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Builder(
                      builder: (context) {
                        final format = ref.watch(selectedPolaroidFormatProvider);
                        return AspectRatio(
                          aspectRatio: format.ratio,
                          child: Image.file(
                            File(widget.imagePath),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Polaroid Chin: Line 1 (Native Script)
                  Text(
                    line1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  // Polaroid Chin: Line 2 (Pronunciation & Translation)
                  const SizedBox(height: 6),
                  Text(
                    '$line2 ${_selectedObject.transliteration != null ? "· ${_selectedObject.transliteration}" : ""}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  // Part of speech / Level badge
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedObject.partOfSpeech ?? "Noun"} • ${_selectedObject.difficultyLevel ?? "Level"}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Controls & Toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _speak,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Listen TTS'),
                ),
                if (isFilipino)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _invertScriptOrder = !_invertScriptOrder;
                      });
                    },
                    icon: const Icon(Icons.swap_vert),
                    label: Text(_invertScriptOrder ? 'Baybayin First' : 'Latin First'),
                  ),
              ],
            ),

            // Secondary Detected Objects Switcher (Filtered by confidence threshold)
            Builder(
              builder: (context) {
                final threshold = ref.watch(confidenceThresholdProvider);
                final confidentObjects = widget.analysisResult.detectedObjects
                    .where((obj) => obj.isConfident(threshold))
                    .toList();

                if (confidentObjects.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Switch Taught Object in Scene:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...confidentObjects.map((obj) {
                      final isSelected = obj.id == _selectedObject.id;
                      return Card(
                        color: isSelected ? Colors.orange[50] : Colors.white,
                        elevation: isSelected ? 2 : 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? Colors.orange : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        child: ListTile(
                          leading: IconButton(
                            icon: const Icon(Icons.volume_up),
                            color: isSelected ? Colors.orange[800] : Colors.black54,
                            tooltip: 'Hear pronunciation',
                            onPressed: () => _speak(obj),
                          ),
                          title: Text(
                            '${obj.targetWord} (${obj.labelEn})',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text('${obj.secondaryScript ?? ""} · ${obj.transliteration ?? ""}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${obj.confidencePercentage}% confident',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.orange)
                                  : const Icon(Icons.circle_outlined),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedObject = obj;
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Save button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _isSaving ? null : _savePolaroid,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save to Scrapbook', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
