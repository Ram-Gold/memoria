import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/services/app_tts_service.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/models/polaroid.dart';

class PolaroidDetailScreen extends ConsumerStatefulWidget {
  final Polaroid polaroid;

  const PolaroidDetailScreen({super.key, required this.polaroid});

  @override
  ConsumerState<PolaroidDetailScreen> createState() => _PolaroidDetailScreenState();
}

class _PolaroidDetailScreenState extends ConsumerState<PolaroidDetailScreen> {
  final AppTtsService _ttsService = AppTtsService();

  @override
  void initState() {
    super.initState();
    _ttsService.init();
  }

  Future<void> _speak([DetectedObject? obj]) async {
    final word = obj?.targetWord ?? widget.polaroid.selectedWord;
    final secondary = obj?.secondaryScript ?? widget.polaroid.secondaryScript;
    final translit = obj?.transliteration ?? widget.polaroid.transliteration;

    final result = await _ttsService.speak(
      languageCode: widget.polaroid.languageCode,
      targetWord: word,
      secondaryScript: secondary,
      transliteration: translit,
    );

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
        title: const Text('Delete Polaroid?'),
        content: const Text('Are you sure you want to remove this exposure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(p.selectedWord),
        actions: [
          IconButton(
            icon: Icon(p.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
            onPressed: () {
              ref.read(polaroidsProvider.notifier).toggleFavorite(p.id, !p.isFavorite);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Column(
                children: [
                  File(p.imagePath).existsSync()
                      ? Image.file(
                          File(p.imagePath),
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, size: 48)),
                        ),
                  const SizedBox(height: 16),
                  Text(
                    p.selectedWord,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${p.secondaryScript ?? ""} · ${p.transliteration ?? ""}',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${p.partOfSpeech ?? ""} • ${p.difficultyLevel ?? ""}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _speak,
              icon: const Icon(Icons.volume_up),
              label: const Text('Hear Pronunciation'),
            ),
            const SizedBox(height: 12),
            Text('Saved on: ${p.createdAt.toLocal().toString().split(".")[0]}'),
            Text('Language: ${p.languageCode.toUpperCase()}'),
            Builder(
              builder: (context) {
                final threshold = ref.watch(confidenceThresholdProvider);
                final confidentObjects = p.detectedObjects
                    .where((o) => o.isConfident(threshold))
                    .toList();

                if (confidentObjects.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('All Objects in this Memory:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...confidentObjects.map((o) => ListTile(
                          dense: true,
                          leading: IconButton(
                            icon: const Icon(Icons.volume_up, size: 20),
                            tooltip: 'Hear pronunciation',
                            onPressed: () => _speak(o),
                          ),
                          title: Text('${o.targetWord} (${o.labelEn})'),
                          subtitle: Text('${o.secondaryScript ?? ""} · ${o.transliteration ?? ""}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${o.confidencePercentage}% match',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          onTap: () => _speak(o),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
