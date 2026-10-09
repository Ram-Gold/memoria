import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/services/app_tts_service.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../core/widgets/rubber_stamp.dart';
import '../../core/widgets/washi_tape.dart';
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
  final AppTtsService _ttsService = AppTtsService();
  DetectedObject? _selectedObject;
  bool _isPlayingAudio = false;

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

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.polaroid;
    final lang = LanguageRegistry.findByCode(p.languageCode);
    final activeWord = _selectedObject?.targetWord ?? p.selectedWord;
    final activeTranslit = _selectedObject?.transliteration ?? p.transliteration ?? '';
    final activeSecondary = _selectedObject?.secondaryScript ?? p.secondaryScript ?? '';
    final activePos = _selectedObject?.partOfSpeech ?? p.partOfSpeech ?? 'Noun';
    final activeDiff = _selectedObject?.difficultyLevel ?? p.difficultyLevel ?? 'N5';
    final threshold = ref.watch(confidenceThresholdProvider);
    final confidentObjects = p.detectedObjects.where((o) => o.isConfident(threshold)).toList();

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
          icon: const Icon(Icons.arrow_back),
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
              p.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: MemoriaTokens.stampVermilion,
            ),
            tooltip: 'Favorite Exposure',
            onPressed: () {
              ref.read(polaroidsProvider.notifier).toggleFavorite(p.id, !p.isFavorite);
            },
          ),
          // Delete option
          IconButton(
            icon: const Icon(Icons.delete_outline),
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
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  File(p.imagePath).existsSync()
                                      ? Image.file(File(p.imagePath), fit: BoxFit.cover)
                                      : Container(
                                          color: MemoriaTokens.surfaceContainerHigh,
                                          child: const Center(
                                            child: Icon(Icons.broken_image, size: 48, color: MemoriaTokens.outline),
                                          ),
                                        ),

                                  // Subtle film grain gradient scrim
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.35),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Optical Focus Reticle Over Selected Object
                                  Center(
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          width: 1.8,
                                        ),
                                        color: Colors.white.withValues(alpha: 0.12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.center_focus_strong, color: Colors.white, size: 20),
                                          const SizedBox(height: 2),
                                          Text(
                                            activeWord,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Film Roll Stamp in bottom corner
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        'MEM-200 · ISO 400',
                                        style: MemoriaTokens.telemetryMono(
                                          fontSize: 8,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                                    isStamped: p.isFavorite,
                                    onTap: () {
                                      ref.read(polaroidsProvider.notifier).toggleFavorite(p.id, !p.isFavorite);
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
                            Text(lang.flagEmoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 5),
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
                                  : const Icon(Icons.volume_up, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Lexical Block
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MemoriaTokens.tertiaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                        ),
                        child: Text(
                          '$activePos • $activeDiff',
                          style: MemoriaTokens.labelSm(color: MemoriaTokens.tertiary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedObject?.labelEn != null
                              ? 'Contextual translation: ${_selectedObject!.labelEn}'
                              : 'Language learning artifact',
                          style: MemoriaTokens.bodyMd(color: MemoriaTokens.onSurface),
                        ),
                      ),
                    ],
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
          ],
        ),
      ),
    );
  }
}
