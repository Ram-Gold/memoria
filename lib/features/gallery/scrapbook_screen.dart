import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:turnable_page/turnable_page.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../core/widgets/polaroid_frame.dart';
import '../../domain/models/polaroid.dart';

/// Memoria Full-Size Turnable Journal Scrapbook
/// Uses 3D TurnablePage physics across full-bleed graph pages.
/// Holds strictly Polaroids (6 per page) across both front and back pages.
class ScrapbookScreen extends ConsumerStatefulWidget {
  const ScrapbookScreen({super.key});

  @override
  ConsumerState<ScrapbookScreen> createState() => _ScrapbookScreenState();
}

class _ScrapbookScreenState extends ConsumerState<ScrapbookScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageFlipController _pageFlipController = PageFlipController();

  int _viewMode = 0; // 0: Turnable Journal, 1: Collections
  int _currentPageIndex = 0; // 0-based page index

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

    return Scaffold(
      backgroundColor: MemoriaTokens.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─────────────────────────────────────────────────────────────
            // 1. FIXED TOP HEADER & SEARCH BAR (OUTSIDE THE NOTEBOOK)
            // ─────────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Column(
                children: [
                  // View Switcher Capsule (Turnable Journal vs Collections)
                  Container(
                    padding: const EdgeInsets.all(3),
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
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: _viewMode == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                                boxShadow: _viewMode == 0
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x14000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.bookOpen,
                                    size: 15,
                                    color: _viewMode == 0 ? MemoriaTokens.primary : MemoriaTokens.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Turnable Journal',
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
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: _viewMode == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                                boxShadow: _viewMode == 1
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x14000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.folderHeart,
                                    size: 15,
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

                  const SizedBox(height: 8),

                  // Dedicated Search Bar with pixel-perfect InputDecorator layout
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                      border: Border.all(color: MemoriaTokens.polaroidBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      style: MemoriaTokens.bodySm(),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search memories (word, romanization)...',
                        hintStyle: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                        prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                        prefixIcon: const Icon(LucideIcons.search, size: 16, color: MemoriaTokens.outline),
                        suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _searchController.clear();
                                  ref.read(scrapbookSearchQueryProvider.notifier).state = '';
                                  setState(() {});
                                },
                                child: const Center(
                                  child: Icon(LucideIcons.x, size: 14, color: MemoriaTokens.outline),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onChanged: (val) {
                        ref.read(scrapbookSearchQueryProvider.notifier).state = val;
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────────────────────────────
            // 2. FULL-SIZE 3D TURNABLE NOTEBOOK (NO SPINE, STRICTLY POLAROIDS)
            // ─────────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(_viewMode == 0 ? 0 : 10, 0, 10, 10),
                child: _viewMode == 0
                    ? _buildTurnableJournal(asyncPolaroids, query)
                    : _buildCollectionsContainer(allPolaroidsAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-size turnable journal: strictly holds Polaroids across every page
  Widget _buildTurnableJournal(AsyncValue<List<Polaroid>> asyncPolaroids, String query) {
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
            return _buildSearchEmptyState(query);
          }
          return _buildEmptyJournalState();
        }

        // Each page holds up to 6 Polaroids.
        // Both front and back pages hold Polaroids.
        final calculatedPages = (polaroids.length / 6).ceil();
        // Provide at least 2 pages so the single page can curl and fold
        final totalPageCount = max(2, calculatedPages);

        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F2EB),
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0C3C2D1E), // Soft, airy, diffused shadow
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // ─── SLIM BOOK-CLOTH / LINEN SPINE ILLUSION (UNDERNEATH) ────
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildSlimBookSpine(),
                    ),

                    // ─── FULL-SIZE 3D TURNABLE PAGE (SWEEPS ABOVE THE SPINE) ───
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return TurnablePage(
                            controller: _pageFlipController,
                            pageCount: totalPageCount,
                            aspectRatio: constraints.maxWidth / constraints.maxHeight,
                            pageViewMode: PageViewMode.single,
                            paperBoundaryDecoration: const PaperBoundaryDecoration(
                              baseColor: Colors.transparent,
                              shadowColor: Color(0x10000000), // Softened shadow
                              borderColor: Colors.transparent,
                              innerBorderColor: Colors.transparent,
                              glowColor: Colors.transparent,
                              gradientStartColor: Colors.transparent,
                              gradientMiddleColor: Colors.transparent,
                              gradientEndColor: Colors.transparent,
                              finalBorderColor: Colors.transparent,
                              finalShadowColor: Color(0x0E000000), // Softened shadow
                              finalShadowBlurRadius: 4.0,
                              borderRadius: 0.0,
                            ),
                            settings: FlipSettings(
                              pageViewMode: PageViewMode.single,
                              flippingTime: 650,
                              drawShadow: true,
                              maxShadowOpacity: 0.30, // 50% softer 3D curl shadow
                              centerShadowColor: Colors.black.withValues(alpha: 0.10),
                              outerShadowColor: Colors.black.withValues(alpha: 0.12),
                              innerShadowColor: Colors.black.withValues(alpha: 0.08),
                              perimeterShadowColor: Colors.black.withValues(alpha: 0.06),
                              mobileScrollSupport: true,
                              cornerTriggerAreaSize: 0.18,
                              swipeDistance: 25,
                            ),
                            onPageChanged: (leftIndex, rightIndex) {
                              if (mounted) {
                                setState(() {
                                  _currentPageIndex = leftIndex.clamp(0, totalPageCount - 1);
                                });
                              }
                            },
                            builder: (context, pageIndex, pageConstraints) {
                              return _buildPolaroidPage(
                                pageIndex: pageIndex,
                                polaroids: polaroids,
                                totalPageCount: totalPageCount,
                                constraints: pageConstraints,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ─── TACTILE PAGE TURN INDICATOR & CONTROLS ─────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: _buildPageIndicatorBar(totalPageCount),
            ),
          ],
        );
      },
    );
  }

  /// Slim bound-cloth / linen book spine illusion with embossed groove and subtle hinge stitches
  Widget _buildSlimBookSpine() {
    return Container(
      width: 13,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFC7B7A5), // Outer bound curve edge
            Color(0xFFE4D7C8), // Highlighted linen surface
            Color(0xFFB5A28F), // Embossed crease shadow
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        border: Border(
          right: BorderSide(color: Color(0xFF9E8C7A), width: 0.8),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stitchCount = (constraints.maxHeight / 20).floor().clamp(10, 36);
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(stitchCount, (_) {
              return Container(
                width: 2.2,
                height: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF7D6B57).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// Builds a full-size graph paper page holding up to 6 Polaroids strictly
  Widget _buildPolaroidPage({
    required int pageIndex,
    required List<Polaroid> polaroids,
    required int totalPageCount,
    required BoxConstraints constraints,
  }) {
    final startIdx = pageIndex * 6;
    // Alternating subtle organic tilts for scrapbook feel
    const tilts = [-0.02, 0.018, -0.015, 0.022, -0.018, 0.015];

    return Container(
      margin: const EdgeInsets.only(left: 13),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        borderRadius: BorderRadius.zero,
      ),
      child: Stack(
        children: [
          // Clean authentic graph grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: NotebookGridPainter(
                gridColor: const Color(0xFFE8DFD3),
                spacing: 16.0,
              ),
            ),
          ),

          // Subtle page header annotation
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PAGE ${pageIndex + 1}',
                  style: MemoriaTokens.telemetryMono(
                    fontSize: 9,
                    color: const Color(0xFFB5A99B),
                  ),
                ),
                Text(
                  'MEMORIA SCRAPBOOK',
                  style: MemoriaTokens.telemetryMono(
                    fontSize: 9,
                    color: const Color(0xFFB5A99B),
                  ),
                ),
              ],
            ),
          ),

          // 2-column by 3-row grid (strictly 6 Polaroids)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 28, 10, 8),
            child: Column(
              children: List.generate(3, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(2, (col) {
                      final itemSlot = startIdx + (row * 2 + col);
                      if (itemSlot < polaroids.length) {
                        final p = polaroids[itemSlot];
                        final tilt = tilts[itemSlot % tilts.length];

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: 146,
                                child: PolaroidFrame(
                                  imagePath: p.imagePath,
                                  format: PolaroidFormat.square,
                                  primaryText: p.selectedWord,
                                  subtitleText: p.transliteration ?? p.secondaryScript,
                                  showWashiTape: true,
                                  isStamped: p.isFavorite,
                                  angle: tilt,
                                  chinHeight: 34.0,
                                  cardPadding: 5.0,
                                  primaryFontSize: 15,
                                  subtitleFontSize: 9.5,
                                  onTap: () {
                                    context.push('/polaroid/${p.id}', extra: p);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Empty slot on page
                        return const Expanded(
                          child: SizedBox.shrink(),
                        );
                      }
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty scrapbook state with a gentle handwritten note
  Widget _buildEmptyJournalState() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: NotebookGridPainter(
                gridColor: const Color(0xFFE8DFD3),
                spacing: 16.0,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MemoriaTokens.primaryContainer,
                      border: Border.all(color: MemoriaTokens.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.camera, size: 30, color: MemoriaTokens.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your journal is waiting',
                    style: MemoriaTokens.headlineSm(color: MemoriaTokens.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the Camera tab below to snap your first Polaroid and fill this page.',
                    textAlign: TextAlign.center,
                    style: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Search empty state
  Widget _buildSearchEmptyState(String query) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DDD0)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.searchX, size: 42, color: MemoriaTokens.outline),
            const SizedBox(height: 10),
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
      ),
    );
  }

  /// Bottom pagination indicator with tap arrow controls
  Widget _buildPageIndicatorBar(int totalPages) {
    final currentDisplayPage = (_currentPageIndex + 1).clamp(1, totalPages);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
        border: Border.all(color: MemoriaTokens.polaroidBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous Page Button
          GestureDetector(
            onTap: _currentPageIndex > 0
                ? () {
                    HapticFeedback.selectionClick();
                    _pageFlipController.previousPage();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 16,
                color: _currentPageIndex > 0 ? MemoriaTokens.primary : MemoriaTokens.outline.withValues(alpha: 0.4),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Page Index Label
          Text(
            'Page $currentDisplayPage of $totalPages',
            style: MemoriaTokens.labelSm(color: MemoriaTokens.onSurface).copyWith(fontSize: 11),
          ),

          const SizedBox(width: 8),

          // Next Page Button
          GestureDetector(
            onTap: _currentPageIndex < totalPages - 1
                ? () {
                    HapticFeedback.selectionClick();
                    _pageFlipController.nextPage();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: _currentPageIndex < totalPages - 1
                    ? MemoriaTokens.primary
                    : MemoriaTokens.outline.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Collections View: Language-grouped albums
  Widget _buildCollectionsContainer(AsyncValue<List<Polaroid>> allPolaroidsAsync) {
    return allPolaroidsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (polaroids) {
        if (polaroids.isEmpty) {
          return Center(
            child: Text('No collections recorded yet.', style: MemoriaTokens.bodyMd()),
          );
        }

        final Map<String, List<Polaroid>> grouped = {};
        for (final p in polaroids) {
          grouped.putIfAbsent(p.languageCode, () => []).add(p);
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5DDD0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: grouped.entries.map((entry) {
              final lang = LanguageRegistry.findByCode(entry.key);
              final items = entry.value;
              final latest = items.first;

              return GestureDetector(
                onTap: () {
                  ref.read(scrapbookSearchQueryProvider.notifier).state = entry.key;
                  setState(() => _viewMode = 0);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                    border: Border.all(color: MemoriaTokens.polaroidBorder),
                    boxShadow: MemoriaTokens.shadowLevel1,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: PolaroidFrame(
                            imagePath: latest.imagePath,
                            format: PolaroidFormat.square,
                            chinHeight: 0,
                            cardPadding: 2,
                            isElevated: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(lang.flagEmoji, style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 6),
                                Text(
                                  '${lang.displayName} Collection',
                                  style: MemoriaTokens.headlineSm().copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${items.length} developed exposure${items.length == 1 ? '' : 's'}',
                              style: MemoriaTokens.bodySm().copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: MemoriaTokens.outline, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Custom Painter to draw authentic graph grid lines on notebook sheets
class NotebookGridPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;

  NotebookGridPainter({
    required this.gridColor,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.55
      ..style = PaintingStyle.stroke;

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NotebookGridPainter oldDelegate) => false;
}
