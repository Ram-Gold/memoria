import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/languages/sentence_generator.dart';
import '../../core/services/app_tts_service.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../core/widgets/language_flag_icon.dart';
import '../../core/widgets/rubber_stamp.dart';
import '../../core/widgets/washi_tape.dart';
import '../../data/services/local_object_lexicon.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/models/polaroid.dart';

/// Stitch "Polaroid Preview & Archival Workspace"
/// Features physical Polaroid frame, washi tape, Caveat script,
/// pronunciation waveform audio player, and multi-object scene switcher.
class PolaroidDetailScreen extends ConsumerStatefulWidget {
  final Polaroid polaroid;

  const PolaroidDetailScreen({super.key, required this.polaroid});

  @override
  ConsumerState<PolaroidDetailScreen> createState() => _PolaroidDetailScreenState();
}

class _PolaroidDetailScreenState extends ConsumerState<PolaroidDetailScreen> {
  final GlobalKey _polaroidRepaintKey = GlobalKey();
  final AppTtsService _ttsService = AppTtsService();
  DetectedObject? _selectedObject;
  bool _isPlayingAudio = false;
  String? _currentlyPlayingSentence;
  bool? _isFavoriteOverride;
  bool _isSharing = false;
  bool _isDownloading = false;

  Future<void> _speakSentence(String sentence, String languageCode) async {
    HapticFeedback.selectionClick();
    setState(() => _currentlyPlayingSentence = sentence);

    final result = await _ttsService.speak(
      languageCode: languageCode,
      targetWord: sentence,
    );

    if (mounted) {
      setState(() => _currentlyPlayingSentence = null);
    }

    if (!result.success && mounted && result.isMissingVoicePack) {
      final lang = LanguageRegistry.findByCode(languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${lang.displayName} offline voice data missing. Download offline speech data in Android Settings > Google Text-to-Speech.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _toggleFavorite(Polaroid p, bool currentFavorite) {
    final newFavorite = !currentFavorite;
    HapticFeedback.lightImpact();
    setState(() {
      _isFavoriteOverride = newFavorite;
    });
    ref.read(polaroidsProvider.notifier).toggleFavorite(p.id, newFavorite);
  }

  @override
  void initState() {
    super.initState();
    _ttsService.init();

    // Default to the first detected object or primary
    if (widget.polaroid.detectedObjects.isNotEmpty) {
      _selectedObject = widget.polaroid.detectedObjects.firstWhere(
        (o) => o.id == widget.polaroid.selectedObjectId,
        orElse: () => widget.polaroid.detectedObjects.first,
      );
    }
  }

  Future<void> _speak([DetectedObject? obj]) async {
    final target = obj ?? _selectedObject;
    final word = target?.targetWord ?? widget.polaroid.selectedWord;
    final secondary = target?.secondaryScript ?? widget.polaroid.secondaryScript;
    final translit = target?.transliteration ?? widget.polaroid.transliteration;

    setState(() => _isPlayingAudio = true);

    final result = await _ttsService.speak(
      languageCode: widget.polaroid.languageCode,
      targetWord: word,
      secondaryScript: secondary,
      transliteration: translit,
    );

    if (mounted) {
      setState(() => _isPlayingAudio = false);
    }

    if (!result.success && mounted && result.isMissingVoicePack) {
      final lang = LanguageRegistry.findByCode(widget.polaroid.languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${lang.displayName} offline voice data missing. Download offline speech data in Android Settings > Google Text-to-Speech.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MemoriaTokens.surface,
        title: Text('Delete Memory?', style: MemoriaTokens.headlineMd()),
        content: Text(
          'Are you sure you want to discard this physical exposure from your scrapbook?',
          style: MemoriaTokens.bodyMd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: MemoriaTokens.labelLg(color: MemoriaTokens.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: MemoriaTokens.labelLg(color: MemoriaTokens.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(polaroidsProvider.notifier).deletePolaroid(widget.polaroid.id);
      if (mounted) context.pop();
    }
  }

  /// Captures the physical Polaroid card (with frame, calligraphy, and stamp) as a PNG file.
  Future<File?> _capturePolaroidImage() async {
    try {
      final boundary = _polaroidRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/polaroid_${widget.polaroid.id}_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes, flush: true);
      return tempFile;
    } catch (e) {
      debugPrint('Error rendering Polaroid print: $e');
      return null;
    }
  }

  /// Prompts the native Android share sheet with only the image file
  Future<void> _sharePolaroid() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final imageFile = await _capturePolaroidImage();
      if (imageFile != null && mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imageFile.path, mimeType: 'image/png')],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not prepare photo for sharing.')),
        );
      }
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  /// Saves the rendered Polaroid print directly to the device's photo gallery
  Future<void> _downloadPolaroid() async {
    if (_isDownloading) return;
    HapticFeedback.lightImpact();
    setState(() => _isDownloading = true);

    try {
      final imageFile = await _capturePolaroidImage();
      if (imageFile != null) {
        await Gal.putImage(imageFile.path, album: 'Memoria');
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: MemoriaTokens.surfaceContainerHighest,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                side: const BorderSide(color: MemoriaTokens.polaroidBorder),
              ),
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: MemoriaTokens.secondary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Polaroid saved to Photos!',
                    style: MemoriaTokens.labelLg(color: MemoriaTokens.onSurface),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture photo.')),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save to gallery: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
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
    final polaroidsAsync = ref.watch(polaroidsProvider);
    final currentPolaroid = polaroidsAsync.valueOrNull?.firstWhere(
          (item) => item.id == widget.polaroid.id,
          orElse: () => widget.polaroid,
        ) ?? widget.polaroid;
    final isFavorite = _isFavoriteOverride ?? currentPolaroid.isFavorite;
    final p = currentPolaroid.copyWith(isFavorite: isFavorite);

    final lang = LanguageRegistry.findByCode(p.languageCode);
    final activeWord = _selectedObject?.targetWord ?? p.selectedWord;
    final activeTranslit = _selectedObject?.transliteration ?? p.transliteration ?? '';
    final activeSecondary = _selectedObject?.secondaryScript ?? p.secondaryScript ?? '';
    final activePos = _selectedObject?.partOfSpeech ?? p.partOfSpeech ?? 'Noun';
    final activeDiff = _selectedObject?.difficultyLevel ?? p.difficultyLevel ?? 'N5';
    final threshold = ref.watch(confidenceThresholdProvider);
    final confidentObjects = p.detectedObjects.where((o) => o.isConfident(threshold)).toList();

    // Contextual English meaning with multi-stage foolproof resolution:
    String activeEnglishLabel = '';

    // 1. If an object is explicitly selected by user tap:
    if (_selectedObject != null) {
      final label = _selectedObject!.labelEn.trim();
      if (label.isNotEmpty && label.toLowerCase() != 'object' && label.toLowerCase() != 'item') {
        activeEnglishLabel = label;
      } else {
        // Try reverse lookup on selected object
        final rev = LocalObjectLexicon.reverseLookup(
          targetWord: _selectedObject!.targetWord,
          transliteration: _selectedObject!.transliteration,
          secondaryScript: _selectedObject!.secondaryScript,
          langCode: p.languageCode,
        );
        if (rev != null && rev.labelEn.isNotEmpty) {
          activeEnglishLabel = rev.labelEn;
        }
      }
    }

    // 2. Direct labelEn stored on the Polaroid model itself:
    if (activeEnglishLabel.isEmpty && p.labelEn != null && p.labelEn!.trim().isNotEmpty && p.labelEn!.trim().toLowerCase() != 'object') {
      activeEnglishLabel = p.labelEn!.trim();
    }

    // 3. Match against detectedObjects by selectedObjectId:
    if (activeEnglishLabel.isEmpty && p.selectedObjectId.isNotEmpty) {
      for (final obj in p.detectedObjects) {
        if (obj.id == p.selectedObjectId &&
            obj.labelEn.trim().isNotEmpty &&
            obj.labelEn.trim().toLowerCase() != 'object') {
          activeEnglishLabel = obj.labelEn.trim();
          break;
        }
      }
    }

    // 4. Match against detectedObjects by targetWord or transliteration:
    if (activeEnglishLabel.isEmpty) {
      for (final obj in p.detectedObjects) {
        final matchesWord = obj.targetWord.trim().toLowerCase() == activeWord.trim().toLowerCase();
        final matchesTranslit = activeTranslit.isNotEmpty &&
            obj.transliteration?.trim().toLowerCase() == activeTranslit.trim().toLowerCase();
        if ((matchesWord || matchesTranslit) &&
            obj.labelEn.trim().isNotEmpty &&
            obj.labelEn.trim().toLowerCase() != 'object') {
          activeEnglishLabel = obj.labelEn.trim();
          break;
        }
      }
    }

    // 5. Offline reverse dictionary lookup by target word, transliteration, or secondary script:
    if (activeEnglishLabel.isEmpty) {
      final rev = LocalObjectLexicon.reverseLookup(
        targetWord: activeWord,
        transliteration: activeTranslit,
        secondaryScript: activeSecondary,
        langCode: p.languageCode,
      );
      if (rev != null && rev.labelEn.isNotEmpty) {
        activeEnglishLabel = rev.labelEn;
      }
    }

    // 6. Direct lookup (in case activeWord is already English):
    if (activeEnglishLabel.isEmpty) {
      final match = LocalObjectLexicon.lookup(
        className: activeWord,
        langCode: p.languageCode,
      );
      if (match != null && match.labelEn.isNotEmpty) {
        activeEnglishLabel = match.labelEn;
      }
    }

    // 7. Check if any detected object has a valid label:
    if (activeEnglishLabel.isEmpty && p.detectedObjects.isNotEmpty) {
      for (final obj in p.detectedObjects) {
        if (obj.labelEn.trim().isNotEmpty && obj.labelEn.trim().toLowerCase() != 'object') {
          activeEnglishLabel = obj.labelEn.trim();
          break;
        }
      }
    }

    // 8. Use Polaroid's resolvedEnglishLabel fallback
    if (activeEnglishLabel.isEmpty) {
      activeEnglishLabel = p.resolvedEnglishLabel;
    }

    // Format date string
    final date = p.createdAt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final timeStr =
        '${months[date.month - 1]} ${date.day} • ${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';

    return Scaffold(
      backgroundColor: MemoriaTokens.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${lang.displayName} Archive',
          style: MemoriaTokens.headlineSm(),
        ),
        actions: [
          // Favorite rubber stamp toggle
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : LucideIcons.heart,
              color: isFavorite ? MemoriaTokens.stampVermilion : MemoriaTokens.outline,
            ),
            tooltip: 'Favorite Exposure',
            onPressed: () => _toggleFavorite(p, isFavorite),
          ),
          // Delete option
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            tooltip: 'Delete Memory',
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // 1. Hero Polaroid Print Artifact Workspace
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Physical Polaroid Frame
                  Transform.rotate(
                    angle: 0.015,
                    child: RepaintBoundary(
                      key: _polaroidRepaintKey,
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
                            // Photographic Aperture Window
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    width: 0.8,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: File(p.imagePath).existsSync()
                                    ? Image.file(File(p.imagePath), fit: BoxFit.cover)
                                    : Container(
                                        color: MemoriaTokens.surfaceContainerHigh,
                                        child: const Center(
                                          child: Icon(LucideIcons.imageOff, size: 48, color: MemoriaTokens.outline),
                                        ),
                                      ),
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
                                        activeWord,
                                        textAlign: TextAlign.center,
                                        style: MemoriaTokens.handwrittenChin(
                                          fontSize: 32,
                                          color: MemoriaTokens.onSurface,
                                        ),
                                      ),
                                      if (activeSecondary.isNotEmpty || activeTranslit.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          activeSecondary.isNotEmpty
                                              ? '$activeSecondary · $activeTranslit'
                                              : activeTranslit,
                                          style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Rubber Heart Ink Stamp
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: RubberStampWidget(
                                      isStamped: isFavorite,
                                      onTap: () => _toggleFavorite(p, isFavorite),
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

            // 2. Archival & Learning Card
            Container(
              decoration: BoxDecoration(
                color: MemoriaTokens.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(MemoriaTokens.radiusLg),
                border: Border.all(color: MemoriaTokens.polaroidBorder, width: 1),
                boxShadow: MemoriaTokens.shadowLevel1,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Metadata Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MemoriaTokens.secondaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LanguageFlagIcon(
                              language: lang,
                              width: 16,
                              borderRadius: 2.0,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lang.displayName,
                              style: MemoriaTokens.labelSm(color: MemoriaTokens.secondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        timeStr,
                        style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Interactive Pronunciation & Waveform Bar
                  Container(
                    decoration: BoxDecoration(
                      color: MemoriaTokens.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRONUNCIATION GUIDE',
                              style: MemoriaTokens.labelSm(color: MemoriaTokens.onSurfaceVariant),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  activeTranslit.isNotEmpty ? activeTranslit : activeWord,
                                  style: MemoriaTokens.headlineSm(color: MemoriaTokens.onSurface),
                                ),
                                if (activeSecondary.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '($activeSecondary)',
                                    style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        // TTS Audio Trigger Button
                        GestureDetector(
                          onTap: () => _speak(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MemoriaTokens.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: MemoriaTokens.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isPlayingAudio
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(LucideIcons.volume2, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // English Meaning & Lexical Classification Row
                  Container(
                    decoration: BoxDecoration(
                      color: MemoriaTokens.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                      border: Border.all(
                        color: MemoriaTokens.polaroidBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ENGLISH MEANING',
                              style: MemoriaTokens.labelSm(
                                color: MemoriaTokens.onSurfaceVariant,
                              ).copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MemoriaTokens.tertiaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                              ),
                              child: Text(
                                '$activePos • $activeDiff',
                                style: MemoriaTokens.labelSm(
                                  color: MemoriaTokens.tertiary,
                                ).copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.languages,
                              size: 18,
                              color: MemoriaTokens.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activeEnglishLabel.isNotEmpty
                                    ? activeEnglishLabel
                                    : (p.resolvedEnglishLabel.isNotEmpty ? p.resolvedEnglishLabel : 'Item'),
                                style: MemoriaTokens.headlineSm(
                                  color: MemoriaTokens.onSurface,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Multi-Object Scene Switcher Chips
                  if (confidentObjects.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: MemoriaTokens.surfaceContainerHigh, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Objects in this Memory:',
                          style: MemoriaTokens.labelSm(color: MemoriaTokens.onSurfaceVariant),
                        ),
                        Text(
                          '${confidentObjects.length} Recognized',
                          style: MemoriaTokens.labelSm(color: MemoriaTokens.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...confidentObjects.map((obj) {
                      final isSelected = _selectedObject?.id == obj.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedObject = obj);
                          _speak(obj);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? MemoriaTokens.primaryContainer
                                : MemoriaTokens.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                            border: Border.all(
                              color: isSelected
                                  ? MemoriaTokens.primary
                                  : MemoriaTokens.polaroidBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? MemoriaTokens.primary
                                      : MemoriaTokens.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${obj.targetWord} (${obj.labelEn})',
                                  style: MemoriaTokens.labelSm(
                                    color: isSelected
                                        ? MemoriaTokens.primaryDark
                                        : MemoriaTokens.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MemoriaTokens.secondaryContainer.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${obj.confidencePercentage}% match',
                                  style: MemoriaTokens.labelSm(color: MemoriaTokens.secondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. Contextual Example Sentences Card
            _buildExampleSentencesSection(
              languageCode: p.languageCode,
              word: activeWord,
              labelEn: activeEnglishLabel.isNotEmpty ? activeEnglishLabel : p.resolvedEnglishLabel,
              secondaryScript: activeSecondary,
              transliteration: activeTranslit,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: MemoriaTokens.surface,
            border: Border(
              top: BorderSide(
                color: MemoriaTokens.polaroidBorder.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // "Share this Photo" Pill Button
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _sharePolaroid,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.share2, size: 18),
                  label: Text(
                    _isSharing ? 'Preparing...' : 'Share this Photo',
                    style: MemoriaTokens.labelLg(color: Colors.white),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: MemoriaTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Download Icon Button on the Bottom Right
              Material(
                color: MemoriaTokens.surfaceContainerHighest,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _isDownloading ? null : _downloadPolaroid,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MemoriaTokens.polaroidBorder,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MemoriaTokens.primary,
                              ),
                            )
                          : const Icon(
                              LucideIcons.download,
                              size: 22,
                              color: MemoriaTokens.onSurface,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleSentencesSection({
    required String languageCode,
    required String word,
    required String labelEn,
    String? secondaryScript,
    String? transliteration,
  }) {
    final sentences = SentenceGeneratorService.generate(
      languageCode: languageCode,
      targetWord: word,
      labelEn: labelEn,
      secondaryScript: secondaryScript,
      transliteration: transliteration,
    );

    return Container(
      decoration: BoxDecoration(
        color: MemoriaTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MemoriaTokens.radiusLg),
        border: Border.all(color: MemoriaTokens.polaroidBorder, width: 1),
        boxShadow: MemoriaTokens.shadowLevel1,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title Header
          Row(
            children: [
              const Icon(
                LucideIcons.sparkles,
                size: 16,
                color: MemoriaTokens.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'EXAMPLE SENTENCES IN CONTEXT',
                style: MemoriaTokens.labelSm(
                  color: MemoriaTokens.onSurfaceVariant,
                ).copyWith(letterSpacing: 1.1, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'See how "$word" is naturally used in authentic conversation.',
            style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          // Sentence Cards
          ...sentences.map((item) {
            final isPlaying = _currentlyPlayingSentence == item.nativeSentence;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MemoriaTokens.surfaceContainerLow,
                borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                border: Border.all(
                  color: MemoriaTokens.polaroidBorder.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Style badge + Speaker button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MemoriaTokens.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                        ),
                        child: Text(
                          item.styleLabel.toUpperCase(),
                          style: MemoriaTokens.labelSm(
                            color: MemoriaTokens.primaryDark,
                          ).copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                        ),
                      ),
                      IconButton(
                        icon: isPlaying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: MemoriaTokens.primary,
                                ),
                              )
                            : const Icon(LucideIcons.volume2, size: 18),
                        color: MemoriaTokens.primary,
                        tooltip: 'Listen to sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: isPlaying
                            ? null
                            : () => _speakSentence(item.nativeSentence, languageCode),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Native Target Script
                  SelectableText(
                    item.nativeSentence,
                    style: MemoriaTokens.bodyLg(
                      color: MemoriaTokens.onSurface,
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Transliteration / Romanization
                  Text(
                    item.transliteration,
                    style: MemoriaTokens.bodySm(
                      color: MemoriaTokens.secondary,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 6),

                  // English Translation
                  Text(
                    item.englishTranslation,
                    style: MemoriaTokens.bodyMd(
                      color: MemoriaTokens.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

