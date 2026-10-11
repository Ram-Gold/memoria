import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../app/providers.dart';
import '../../core/languages/baybayin_engine.dart';
import '../../core/languages/chin_format_helper.dart';
import '../../core/services/app_tts_service.dart';
import '../../core/services/tagalog_dictionary_service.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../core/widgets/rubber_stamp.dart';
import '../../core/widgets/washi_tape.dart';
import '../../data/services/local_object_lexicon.dart';
import '../../domain/models/analysis_result.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/models/polaroid.dart';

/// Stitch "Polaroid Reveal & Object Explorer"
/// Combines the physical Polaroid frame with interactive in-photo hotspots,
/// handwritten Caveat script chin, RAG memory recall, and object switcher.
class EditorScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final AnalysisResult analysisResult;
  final String? layoutId;

  const EditorScreen({
    super.key,
    required this.imagePath,
    required this.analysisResult,
    this.layoutId,
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
  bool _isEditing = false;
  late final TextEditingController _wordController;
  late final TextEditingController _meaningController;
  late final TextEditingController _pronunciationController;
  late final TextEditingController _sentenceController;

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
    _wordController = TextEditingController(text: _selectedObject.targetWord);
    _meaningController = TextEditingController(text: _selectedObject.labelEn);
    _pronunciationController = TextEditingController(
      text: _selectedObject.transliteration ?? _selectedObject.secondaryScript ?? '',
    );
    _sentenceController = TextEditingController(text: widget.analysisResult.sceneDescription);
    _ttsService.init();
  }

  void _syncControllersWithObject(DetectedObject obj) {
    if (!_isEditing) {
      _wordController.text = obj.targetWord;
      _meaningController.text = obj.labelEn;
      _pronunciationController.text = obj.transliteration ?? obj.secondaryScript ?? '';
    }
  }

  void _toggleEditing() {
    HapticFeedback.selectionClick();
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save inline edits into current _selectedObject
        final newWord = _wordController.text.trim();
        final newMeaning = _meaningController.text.trim();
        final newPronunciation = _pronunciationController.text.trim();
        _selectedObject = _selectedObject.copyWith(
          targetWord: newWord.isNotEmpty ? newWord : _selectedObject.targetWord,
          labelEn: newMeaning.isNotEmpty ? newMeaning : _selectedObject.labelEn,
          transliteration: newPronunciation.isNotEmpty ? newPronunciation : _selectedObject.transliteration,
        );
      }
    });
  }

  void _autoTranscribe() {
    HapticFeedback.lightImpact();
    final language = ref.read(activeLanguageProvider);
    final word = _wordController.text.trim();
    final meaning = _meaningController.text.trim();

    if (language.code == 'fil' || language.code == 'tl') {
      final dictEntry = TagalogDictionaryService.instance.lookupByEnglish(meaning) ??
          TagalogDictionaryService.instance.lookupByTagalog(word);
      if (dictEntry != null) {
        _wordController.text = dictEntry.baybayin;
        _pronunciationController.text = '${dictEntry.word} · ${dictEntry.pronunciation}';
      } else {
        final tagalogWord = word.isNotEmpty ? word : meaning.toLowerCase();
        final normalized = BaybayinEngine.normalizeTagalogPhonetics(tagalogWord);
        final baybayin = BaybayinEngine.transliterate(normalized);
        final pronunciation = BaybayinEngine.formatPronunciation(tagalogWord);
        _wordController.text = baybayin;
        _pronunciationController.text = '$tagalogWord · $pronunciation';
      }
    } else if (language.code == 'ja') {
      final lex = LocalObjectLexicon.lookup(className: meaning, langCode: 'ja') ??
          LocalObjectLexicon.reverseLookup(targetWord: word, langCode: 'ja');
      if (lex != null) {
        _wordController.text = lex.targetWord;
        _pronunciationController.text = lex.secondaryScript.isNotEmpty
            ? '${lex.secondaryScript} (${lex.transliteration})'
            : lex.transliteration;
      }
    }
    setState(() {});
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

      // Ensure English label and target word are fully resolved, honoring inline edits
      String labelEn = _meaningController.text.trim().isNotEmpty
          ? _meaningController.text.trim()
          : _selectedObject.labelEn.trim();
      String selectedWord = _wordController.text.trim().isNotEmpty
          ? _wordController.text.trim()
          : _selectedObject.targetWord.trim();
      String transliteration = _pronunciationController.text.trim().isNotEmpty
          ? _pronunciationController.text.trim()
          : (_selectedObject.transliteration ?? '');

      if (labelEn.isEmpty || labelEn.toLowerCase() == 'object' || labelEn.toLowerCase() == 'item') {
        final rev = LocalObjectLexicon.reverseLookup(
          targetWord: selectedWord,
          transliteration: transliteration,
          secondaryScript: _selectedObject.secondaryScript,
          langCode: language.code,
        );
        if (rev != null && rev.labelEn.isNotEmpty) {
          labelEn = rev.labelEn;
        }
      }

      final resolvedSelectedObject = _selectedObject.copyWith(
        targetWord: selectedWord,
        labelEn: labelEn.isNotEmpty ? labelEn : _selectedObject.labelEn,
        transliteration: transliteration,
      );

      // Guarantee the focal object selected by the user is ALWAYS preserved,
      // even if its individual confidence score is below the threshold slider.
      final objectsToSave = <DetectedObject>[];
      final existsInConfident = confidentObjects.any((o) => o.id == resolvedSelectedObject.id);
      if (!existsInConfident) {
        objectsToSave.add(resolvedSelectedObject);
      }
      for (final obj in confidentObjects) {
        if (obj.id == resolvedSelectedObject.id) {
          objectsToSave.add(resolvedSelectedObject);
        } else {
          objectsToSave.add(obj);
        }
      }

      final activeFormat = widget.layoutId != null
          ? PolaroidFormat.fromId(widget.layoutId!)
          : ref.read(selectedPolaroidFormatProvider);

      final polaroid = Polaroid(
        id: polId,
        imagePath: widget.imagePath,
        outputImagePath: widget.imagePath,
        languageCode: language.code,
        selectedObjectId: resolvedSelectedObject.id,
        selectedWord: resolvedSelectedObject.targetWord,
        labelEn: labelEn.isNotEmpty ? labelEn : resolvedSelectedObject.labelEn,
        secondaryScript: resolvedSelectedObject.secondaryScript,
        transliteration: resolvedSelectedObject.transliteration,
        partOfSpeech: resolvedSelectedObject.partOfSpeech,
        difficultyLevel: resolvedSelectedObject.difficultyLevel,
        layoutId: activeFormat.id,
        createdAt: DateTime.now(),
        detectedObjects: objectsToSave,
        isFavorite: _isFavorite,
      );

      await ref.read(polaroidsProvider.notifier).addPolaroid(polaroid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circleCheck, color: Colors.white, size: 18),
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
    _wordController.dispose();
    _meaningController.dispose();
    _pronunciationController.dispose();
    _sentenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(activeLanguageProvider);
    final isFilipino = language.code == 'fil';
    final format = widget.layoutId != null
        ? PolaroidFormat.fromId(widget.layoutId!)
        : ref.watch(selectedPolaroidFormatProvider);
    final threshold = ref.watch(confidenceThresholdProvider);
    final confidentObjects = widget.analysisResult.detectedObjects
        .where((o) => o.isConfident(threshold))
        .toList();

    final chinText = ChinFormatHelper.formatFromObject(_selectedObject, language.code);
    final line1 = chinText.line1;
    final line2 = chinText.line2;

    return Scaffold(
      backgroundColor: MemoriaTokens.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.volume2),
            tooltip: 'Pronunciation TTS',
            onPressed: _speak,
          ),
          IconButton(
            icon: Icon(
              _isEditing ? LucideIcons.check : LucideIcons.pencil,
              color: _isEditing ? MemoriaTokens.primary : MemoriaTokens.onSurface,
            ),
            tooltip: _isEditing ? 'Done Editing' : 'Customize Polaroid Text',
            onPressed: _toggleEditing,
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
                  : const Icon(LucideIcons.check, size: 18, color: MemoriaTokens.primary),
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
                                              setState(() {
                                                _selectedObject = obj;
                                                _syncControllersWithObject(obj);
                                              });
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
                                if (_isEditing)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 6,
                                              child: TextField(
                                                controller: _wordController,
                                                textAlign: TextAlign.center,
                                                style: MemoriaTokens.handwrittenChin(
                                                  fontSize: 22,
                                                  color: MemoriaTokens.onSurface,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  hintText: 'Target Word',
                                                  hintStyle: MemoriaTokens.handwrittenChin(
                                                    fontSize: 18,
                                                    color: MemoriaTokens.outline,
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                                  filled: true,
                                                  fillColor: Colors.black.withValues(alpha: 0.04),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                    borderSide: const BorderSide(color: MemoriaTokens.primary, width: 0.8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              flex: 5,
                                              child: TextField(
                                                controller: _meaningController,
                                                textAlign: TextAlign.center,
                                                style: MemoriaTokens.bodySm().copyWith(fontWeight: FontWeight.w600),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  hintText: 'Meaning',
                                                  hintStyle: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                                  filled: true,
                                                  fillColor: Colors.black.withValues(alpha: 0.04),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                    borderSide: const BorderSide(color: MemoriaTokens.polaroidBorder, width: 0.8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: _pronunciationController,
                                          textAlign: TextAlign.center,
                                          style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: 'Pronunciation Guide (e.g. neko, [ak-lat])',
                                            hintStyle: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                            filled: true,
                                            fillColor: Colors.black.withValues(alpha: 0.04),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4),
                                              borderSide: const BorderSide(color: MemoriaTokens.polaroidBorder, width: 0.8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: _toggleEditing,
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          line1,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: MemoriaTokens.handwrittenChin(
                                            fontSize: line1.length > 18 ? 22 : (line1.length > 12 ? 26 : 30),
                                            color: MemoriaTokens.onSurface,
                                          ),
                                        ),
                                        if (line2.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            line2,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                                          ),
                                        ],
                                      ],
                                    ),
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

            if (_isEditing) ...[
              const SizedBox(height: 12),
              ActionChip(
                avatar: const Icon(LucideIcons.sparkles, size: 14, color: MemoriaTokens.primary),
                label: const Text('Auto-Transcribe Pronunciation'),
                labelStyle: MemoriaTokens.labelSm(color: MemoriaTokens.primary),
                backgroundColor: MemoriaTokens.primaryContainer.withValues(alpha: 0.5),
                side: const BorderSide(color: MemoriaTokens.primary, width: 0.8),
                onPressed: _autoTranscribe,
              ),
            ],

            const SizedBox(height: 24),

            // Script Order Switcher for Tagalog / Baybayin
            if (isFilipino) ...[
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _invertScriptOrder = !_invertScriptOrder);
                },
                icon: const Icon(LucideIcons.arrowUpDown, size: 16),
                label: Text(_invertScriptOrder ? 'Baybayin First' : 'Latin First'),
              ),
              const SizedBox(height: 14),
            ],

            // 2. AI Scene Context Card
            if (widget.analysisResult.sceneDescription.isNotEmpty || _isEditing) ...[
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
                    const Icon(LucideIcons.sparkles, size: 18, color: MemoriaTokens.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              controller: _sentenceController,
                              maxLines: 2,
                              style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurface),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Custom scene context or example sentence...',
                                border: InputBorder.none,
                              ),
                            )
                          : Text(
                              '“${_sentenceController.text.isNotEmpty ? _sentenceController.text : widget.analysisResult.sceneDescription}”',
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
                    const Icon(LucideIcons.history, color: Color(0xFFD97706), size: 20),
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
                    const Icon(LucideIcons.bookOpen, color: MemoriaTokens.secondary, size: 20),
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
                    setState(() {
                      _selectedObject = obj;
                      _syncControllersWithObject(obj);
                    });
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
                            LucideIcons.volume2,
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
                icon: const Icon(LucideIcons.bookmarkPlus),
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
