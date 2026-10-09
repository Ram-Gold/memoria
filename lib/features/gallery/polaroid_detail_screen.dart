import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../domain/models/polaroid.dart';

class PolaroidDetailScreen extends ConsumerStatefulWidget {
  final Polaroid polaroid;

  const PolaroidDetailScreen({super.key, required this.polaroid});

  @override
  ConsumerState<PolaroidDetailScreen> createState() => _PolaroidDetailScreenState();
}

class _PolaroidDetailScreenState extends ConsumerState<PolaroidDetailScreen> {
  final FlutterTts _tts = FlutterTts();

  Future<void> _speak() async {
    final lang = LanguageRegistry.findByCode(widget.polaroid.languageCode);
    await _tts.setLanguage(lang.ttsLocale);
    final text = widget.polaroid.secondaryScript ?? widget.polaroid.selectedWord;
    await _tts.speak(text);
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
    _tts.stop();
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
            if (p.detectedObjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('All Objects in this Memory:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...p.detectedObjects.map((o) => ListTile(
                    dense: true,
                    title: Text('${o.targetWord} (${o.labelEn})'),
                    subtitle: Text('${o.secondaryScript ?? ""} · ${o.transliteration ?? ""}'),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
