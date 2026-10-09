import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/providers.dart';
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
  final FlutterTts _tts = FlutterTts();
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
    _initTts();
  }

  Future<void> _initTts() async {
    final language = ref.read(activeLanguageProvider);
    await _tts.setLanguage(language.ttsLocale);
    await _tts.setSpeechRate(0.45);
  }

  Future<void> _speak() async {
    final language = ref.read(activeLanguageProvider);
    await _tts.setLanguage(language.ttsLocale);

    // For Filipino, speak modern Tagalog (secondaryScript). For Japanese, speak secondaryScript (kana).
    final textToSpeak = _selectedObject.secondaryScript ?? _selectedObject.targetWord;
    await _tts.speak(textToSpeak);
  }

  Future<void> _savePolaroid() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final polId = const Uuid().v4();
      final language = ref.read(activeLanguageProvider);

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
        detectedObjects: widget.analysisResult.detectedObjects,
      );

      await ref.read(polaroidsProvider.notifier).addPolaroid(polaroid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Scrapbook!')),
        );
        // Navigate to home (main navigation scaffold)
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
    _tts.stop();
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
            const SizedBox(height: 16),

            // Polaroid Card Frame
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              child: Column(
                children: [
                  // Photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(widget.imagePath),
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
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

            const SizedBox(height: 24),

            // Secondary Detected Objects Switcher
            const Text(
              'Switch Taught Object in Scene:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            ...widget.analysisResult.detectedObjects.map((obj) {
              final isSelected = obj.id == _selectedObject.id;
              return Card(
                color: isSelected ? Colors.orange[50] : null,
                child: ListTile(
                  title: Text('${obj.targetWord} (${obj.labelEn})'),
                  subtitle: Text('${obj.secondaryScript ?? ""} · ${obj.transliteration ?? ""}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.orange)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    setState(() {
                      _selectedObject = obj;
                    });
                  },
                ),
              );
            }),

            const SizedBox(height: 24),

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
