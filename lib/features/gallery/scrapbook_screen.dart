import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../core/widgets/polaroid_frame.dart';
import '../../domain/models/polaroid.dart';

/// Stitch "Memoria Scrapbook Gallery"
/// Features physical Spiral Notebook Spread with wire ring binding,
/// craft paper dot-grid, segmented view switcher, washi tape, and tilted Polaroids.
class ScrapbookScreen extends ConsumerStatefulWidget {
  const ScrapbookScreen({super.key});

  @override
  ConsumerState<ScrapbookScreen> createState() => _ScrapbookScreenState();
}

class _ScrapbookScreenState extends ConsumerState<ScrapbookScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _viewMode = 0; // 0: All Polaroids, 1: Collections

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(scrapbookSearchQueryProvider);
    final asyncPolaroids = ref.watch(scrapbookFilteredPolaroidsProvider);
    final allPolaroidsAsync = ref.watch(polaroidsProvider);
    final totalFilms = allPolaroidsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: MemoriaTokens.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top View Switcher Capsule (All Polaroids vs Collections)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MemoriaTokens.surfaceContainer,
                  borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                  border: Border.all(color: MemoriaTokens.polaroidBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _viewMode = 0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                            boxShadow: _viewMode == 0
                                ? const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.images,
                                size: 16,
                                color: _viewMode == 0 ? MemoriaTokens.primary : MemoriaTokens.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'All Polaroids',
                                style: MemoriaTokens.labelSm(
                                  color: _viewMode == 0 ? MemoriaTokens.primaryDark : MemoriaTokens.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _viewMode = 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                            boxShadow: _viewMode == 1
                                ? const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.folderHeart,
                                size: 16,
                                color: _viewMode == 1 ? MemoriaTokens.primary : MemoriaTokens.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Collections',
                                style: MemoriaTokens.labelSm(
                                  color: _viewMode == 1 ? MemoriaTokens.primaryDark : MemoriaTokens.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // The Spiral Notebook Book Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: const Color(0xFFE5DED4)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A3C2D1E),
                        blurRadius: 24,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Dot-Grid Background Canvas
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DotGridPainter(
                            dotColor: const Color(0xFFDFD5CA),
                            spacing: 16.0,
                            dotRadius: 0.8,
                          ),
                        ),
                      ),

                      // Left Spiral Spine (Double-Wire Binding Rings)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF8F2).withValues(alpha: 0.95),
                            border: const Border(
                              right: BorderSide(color: Color(0xFFECE3D8), width: 1),
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final ringCount = (constraints.maxHeight / 38).floor().clamp(6, 30);
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(ringCount, (index) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Dark Punched Hole
                                      Container(
                                        width: 4,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38332C),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      // Wire Loop Ring
                                      Container(
                                        width: 18,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFC4B8AA),
                                              Color(0xFFEBE3D7),
                                              Color(0xFFD6CABE),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: const Color(0xFFA69A8C), width: 1),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x24000000),
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),

                      // Notebook Main Content Area
                      Padding(
                        padding: const EdgeInsets.only(left: 36, right: 12, top: 12),
                        child: Column(
                          children: [
                            // Notebook Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.bookOpen, color: MemoriaTokens.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Memoria Scrapbook',
                                      style: MemoriaTokens.headlineSm(color: MemoriaTokens.onSurface),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MemoriaTokens.secondaryContainer.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                                    border: Border.all(color: MemoriaTokens.secondary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: MemoriaTokens.secondary,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '$totalFilms Films',
                                        style: MemoriaTokens.labelSm(color: MemoriaTokens.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Notebook Embedded Search Bar
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                                border: Border.all(color: MemoriaTokens.polaroidBorder),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: MemoriaTokens.bodyMd(),
                                decoration: InputDecoration(
                                  hintText: 'Search memories (word, romanization)...',
                                  hintStyle: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: MemoriaTokens.outline),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(LucideIcons.x, size: 16),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(scrapbookSearchQueryProvider.notifier).state = '';
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onChanged: (val) {
                                  ref.read(scrapbookSearchQueryProvider.notifier).state = val;
                                  setState(() {});
                                },
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Main View Switch: Polaroids Grid vs Collections
                            Expanded(
                              child: _viewMode == 0
                                  ? _buildPolaroidsView(asyncPolaroids, query)
                                  : _buildCollectionsView(allPolaroidsAsync),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolaroidsView(AsyncValue<List<Polaroid>> asyncPolaroids, String query) {
    return asyncPolaroids.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MemoriaTokens.primary),
      ),
      error: (err, _) => Center(
        child: Text('Error loading scrapbook: $err', style: MemoriaTokens.bodyMd()),
      ),
      data: (polaroids) {
        if (polaroids.isEmpty) {
          if (query.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.searchX, size: 48, color: MemoriaTokens.outline),
                  const SizedBox(height: 12),
                  Text('No memories found for "$query"', style: MemoriaTokens.bodyMd()),
                  const SizedBox(height: 10),
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

          // Empty Scrapbook Stage
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MemoriaTokens.primaryContainer,
                      border: Border.all(color: MemoriaTokens.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.camera, size: 34, color: MemoriaTokens.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Your Scrapbook is Waiting', style: MemoriaTokens.headlineSm()),
                  const SizedBox(height: 6),
                  Text(
                    'Snap your first real-world memory through the Polaroid lens to begin.',
                    textAlign: TextAlign.center,
                    style: MemoriaTokens.bodySm(),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(navigationIndexProvider.notifier).state = 0;
                    },
                    icon: const Icon(LucideIcons.camera),
                    label: const Text('Open Camera HUD'),
                  ),
                ],
              ),
            ),
          );
        }

        // Alternating organic tilts
        final tilts = [-0.025, 0.02, -0.015, 0.03, -0.02, 0.018];

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 90, top: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: polaroids.length + 1, // +1 for "Snap Memory" card
          itemBuilder: (context, index) {
            // Last item: Tactile Add Photo Card
            if (index == polaroids.length) {
              return GestureDetector(
                onTap: () {
                  ref.read(navigationIndexProvider.notifier).state = 0;
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                    border: Border.all(
                      color: const Color(0xFFD8CDBF),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MemoriaTokens.primaryContainer,
                        ),
                        child: const Icon(
                          LucideIcons.imagePlus,
                          color: MemoriaTokens.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Snap Memory',
                        style: MemoriaTokens.labelLg(color: MemoriaTokens.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add to journal',
                        style: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                      ),
                    ],
                  ),
                ),
              );
            }

            final p = polaroids[index];
            final tiltAngle = tilts[index % tilts.length];

            return PolaroidFrame(
              imagePath: p.imagePath,
              format: PolaroidFormat.square,
              primaryText: p.selectedWord,
              subtitleText: p.transliteration ?? p.secondaryScript,
              showWashiTape: true,
              isStamped: p.isFavorite,
              angle: tiltAngle,
              chinHeight: 52.0,
              onTap: () {
                context.push('/polaroid/${p.id}', extra: p);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCollectionsView(AsyncValue<List<Polaroid>> allPolaroidsAsync) {
    return allPolaroidsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (polaroids) {
        if (polaroids.isEmpty) {
          return Center(
            child: Text('No collections recorded yet.', style: MemoriaTokens.bodyMd()),
          );
        }

        // Group by language
        final Map<String, List<Polaroid>> grouped = {};
        for (final p in polaroids) {
          grouped.putIfAbsent(p.languageCode, () => []).add(p);
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 90, top: 4),
          children: grouped.entries.map((entry) {
            final lang = LanguageRegistry.findByCode(entry.key);
            final items = entry.value;
            final latest = items.first;

            return GestureDetector(
              onTap: () {
                // Filter search by language
                ref.read(scrapbookSearchQueryProvider.notifier).state = entry.key;
                setState(() => _viewMode = 0);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                  border: Border.all(color: MemoriaTokens.polaroidBorder),
                  boxShadow: MemoriaTokens.shadowLevel1,
                ),
                child: Row(
                  children: [
                    // Mini Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: PolaroidFrame(
                          imagePath: latest.imagePath,
                          format: PolaroidFormat.square,
                          chinHeight: 0,
                          cardPadding: 2,
                          isElevated: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(lang.flagEmoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                '${lang.displayName} Collection',
                                style: MemoriaTokens.headlineSm(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${items.length} developed exposure${items.length == 1 ? '' : 's'}',
                            style: MemoriaTokens.bodySm(),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, color: MemoriaTokens.outline),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Custom Painter to draw a fine craft paper dot-grid pattern
class DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotRadius;

  DotGridPainter({
    required this.dotColor,
    required this.spacing,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) => false;
}
