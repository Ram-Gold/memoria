import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';

class ScrapbookScreen extends ConsumerStatefulWidget {
  const ScrapbookScreen({super.key});

  @override
  ConsumerState<ScrapbookScreen> createState() => _ScrapbookScreenState();
}

class _ScrapbookScreenState extends ConsumerState<ScrapbookScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(scrapbookSearchQueryProvider);
    final asyncPolaroids = ref.watch(scrapbookFilteredPolaroidsProvider);

    return Column(
      children: [
          // Indexed Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search memories (word, romaji, object)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(scrapbookSearchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                ref.read(scrapbookSearchQueryProvider.notifier).state = val;
                setState(() {});
              },
            ),
          ),

          // Polaroids Grid or Empty State
          Expanded(
            child: asyncPolaroids.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading scrapbook: $err')),
              data: (polaroids) {
                if (polaroids.isEmpty) {
                  if (query.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No memories matching "$query"'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(scrapbookSearchQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                            child: const Text('Clear Search'),
                          ),
                        ],
                      ),
                    );
                  }

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
                          onPressed: () {
                            ref.read(navigationIndexProvider.notifier).state = 0;
                            context.go('/');
                          },
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
          ),
        ],
      );
    }
  }

