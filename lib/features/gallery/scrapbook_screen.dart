import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';

class ScrapbookScreen extends ConsumerWidget {
  const ScrapbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPolaroids = ref.watch(polaroidsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoria Scrapbook'),
      ),
      body: asyncPolaroids.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading scrapbook: $err')),
        data: (polaroids) {
          if (polaroids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_album_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No Polaroids developed yet.'),
                  const SizedBox(height: 8),
                  const Text('Take a picture with the camera to start learning!'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Open Camera'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: polaroids.length,
            itemBuilder: (context, index) {
              final p = polaroids[index];
              return InkWell(
                onTap: () {
                  context.push('/polaroid/${p.id}', extra: p);
                },
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: File(p.imagePath).existsSync()
                              ? Image.file(File(p.imagePath), fit: BoxFit.cover)
                              : Container(color: Colors.grey[200]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.selectedWord,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          p.secondaryScript ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
