import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:turnable_page/turnable_page.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../core/widgets/language_flag_icon.dart';
import '../../core/widgets/polaroid_frame.dart';
import '../../domain/models/polaroid.dart';
import 'scrapbook_screen.dart';

/// Dedicated Collection Album Screen for a specific language
/// Implemented as a full-size 3D Turnable Journal Book with page-flipping physics,
/// graph paper background, organic tilts, and tap-to-inspect memory detail view.
class CollectionAlbumScreen extends ConsumerStatefulWidget {
  final String languageCode;

  const CollectionAlbumScreen({
    super.key,
    required this.languageCode,
  });

  @override
  ConsumerState<CollectionAlbumScreen> createState() => _CollectionAlbumScreenState();
}

class _CollectionAlbumScreenState extends ConsumerState<CollectionAlbumScreen> {
  final PageFlipController _pageFlipController = PageFlipController();

  @override
  Widget build(BuildContext context) {
    final lang = LanguageRegistry.findByCode(widget.languageCode);
    final allPolaroidsAsync = ref.watch(polaroidsProvider);

    return Scaffold(
      backgroundColor: MemoriaTokens.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─────────────────────────────────────────────────────────────
            // 1. TOP HEADER (BACK BUTTON & COLLECTION INFO)
            // ─────────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(LucideIcons.arrowLeft, color: MemoriaTokens.onSurface, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      side: const BorderSide(color: Color(0xFFE5DDD0)),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            LanguageFlagIcon(
                              language: lang,
                              width: 22,
                              borderRadius: 3.5,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${lang.displayName} Collection',
                                style: MemoriaTokens.headlineSm().copyWith(fontSize: 17),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        allPolaroidsAsync.when(
                          data: (all) {
                            final count = all.where((p) => p.languageCode == widget.languageCode).length;
                            return Text(
                              '$count developed exposure${count == 1 ? '' : 's'}',
                              style: MemoriaTokens.bodySm().copyWith(fontSize: 11, color: MemoriaTokens.outline),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────────────────────────────
            // 2. FULL-SIZE 3D TURNABLE NOTEBOOK FOR THIS COLLECTION
            // ─────────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 10, 85),
                child: allPolaroidsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: MemoriaTokens.primary),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading collection album: $err', style: MemoriaTokens.bodyMd()),
                  ),
                  data: (all) {
                    final polaroids = all.where((p) => p.languageCode == widget.languageCode).toList();

                    if (polaroids.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.images, size: 48, color: MemoriaTokens.outline),
                            const SizedBox(height: 12),
                            Text(
                              'No exposures in this collection yet.',
                              style: MemoriaTokens.bodyMd(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Snap photos in ${lang.displayName} mode to build your collection.',
                              style: MemoriaTokens.bodySm(),
                            ),
                          ],
                        ),
                      );
                    }

                    // 6 Polaroids per page
                    final calculatedPages = (polaroids.length / 6).ceil();
                    final totalPageCount = max(2, calculatedPages);

                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F2EB),
                        borderRadius: BorderRadius.zero,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0C3C2D1E),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // ─── SLIM BOOK SPINE ILLUSION ────
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
                                    shadowColor: Color(0x10000000),
                                    borderColor: Colors.transparent,
                                    innerBorderColor: Colors.transparent,
                                    glowColor: Colors.transparent,
                                    gradientStartColor: Colors.transparent,
                                    gradientMiddleColor: Colors.transparent,
                                    gradientEndColor: Colors.transparent,
                                    finalBorderColor: Colors.transparent,
                                    finalShadowColor: Color(0x0E000000),
                                    finalShadowBlurRadius: 4.0,
                                    borderRadius: 0.0,
                                  ),
                                  settings: FlipSettings(
                                    pageViewMode: PageViewMode.single,
                                    flippingTime: 650,
                                    drawShadow: true,
                                    maxShadowOpacity: 0.30,
                                    centerShadowColor: Colors.black.withValues(alpha: 0.10),
                                    outerShadowColor: Colors.black.withValues(alpha: 0.12),
                                    innerShadowColor: Colors.black.withValues(alpha: 0.08),
                                    perimeterShadowColor: Colors.black.withValues(alpha: 0.06),
                                    mobileScrollSupport: true,
                                    cornerTriggerAreaSize: 0.18,
                                    swipeDistance: 25,
                                  ),
                                  onPageChanged: (leftIndex, rightIndex) {},
                                  builder: (context, pageIndex, pageConstraints) {
                                    return _buildPolaroidPage(
                                      pageIndex: pageIndex,
                                      polaroids: polaroids,
                                      collectionName: lang.displayName,
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
    required String collectionName,
    required int totalPageCount,
    required BoxConstraints constraints,
  }) {
    final startIdx = pageIndex * 6;
    const tilts = [-0.02, 0.018, -0.015, 0.022, -0.018, 0.015];

    return Container(
      margin: const EdgeInsets.only(left: 13),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        borderRadius: BorderRadius.zero,
      ),
      child: Stack(
        children: [
          // Authentic graph grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: NotebookGridPainter(
                gridColor: const Color(0xFFE8DFD3),
                spacing: 16.0,
              ),
            ),
          ),

          // Page header annotation
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
                  '${collectionName.toUpperCase()} COLLECTION',
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
}
