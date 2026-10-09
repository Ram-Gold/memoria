import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../core/services/app_tts_service.dart';
import '../../core/theme/memoria_tokens.dart';
import '../../domain/models/polaroid.dart';

/// Stitch "Memoria - Calendar Overview & Daily Log"
/// Features a tactile monthly calendar matrix where dates with exposures display
/// mini Polaroid tiles with shot counters, notebook grid texture, and interactive daily logs.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  final AppTtsService _ttsService = AppTtsService();

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = now;
    });
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _formatFullDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final asyncPolaroids = ref.watch(polaroidsProvider);

    return Scaffold(
      backgroundColor: MemoriaTokens.surface,
      body: SafeArea(
        bottom: false,
        child: asyncPolaroids.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: MemoriaTokens.primary),
          ),
          error: (err, _) => Center(
            child: Text('Error: $err', style: MemoriaTokens.bodyMd()),
          ),
          data: (polaroids) {
            // Group polaroids by date YYYY-MM-DD
            final Map<String, List<Polaroid>> dateMap = {};
            for (final p in polaroids) {
              final key = _formatDateKey(p.createdAt);
              dateMap.putIfAbsent(key, () => []).add(p);
            }

            final currentMonthPolaroids = polaroids.where((p) =>
                p.createdAt.year == _currentMonth.year &&
                p.createdAt.month == _currentMonth.month).toList();

            final selectedDateKey = _selectedDate != null ? _formatDateKey(_selectedDate!) : null;
            final selectedDayExposures = selectedDateKey != null ? (dateMap[selectedDateKey] ?? []) : <Polaroid>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Month Header & Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _prevMonth,
                            icon: const Icon(LucideIcons.chevronLeft),
                            style: IconButton.styleFrom(
                              backgroundColor: MemoriaTokens.surfaceContainer,
                              iconSize: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatMonthYear(_currentMonth),
                            style: MemoriaTokens.headlineMd(),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _jumpToToday,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: MemoriaTokens.surfaceContainer,
                                borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                                border: Border.all(color: MemoriaTokens.polaroidBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.calendar, size: 14, color: MemoriaTokens.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Today',
                                    style: MemoriaTokens.labelSm(color: MemoriaTokens.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _nextMonth,
                            icon: const Icon(LucideIcons.chevronRight),
                            style: IconButton.styleFrom(
                              backgroundColor: MemoriaTokens.surfaceContainer,
                              iconSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Monthly Summary Ribbon
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: MemoriaTokens.primaryContainer,
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                          ),
                          child: Text(
                            '${currentMonthPolaroids.length} exposures this month',
                            style: MemoriaTokens.labelSm(color: MemoriaTokens.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Large Tactile Monthly Calendar Matrix
                  Container(
                    decoration: BoxDecoration(
                      color: MemoriaTokens.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusLg),
                      border: Border.all(color: MemoriaTokens.polaroidBorder),
                      boxShadow: MemoriaTokens.shadowLevel1,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Weekday Labels
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                                .map(
                                  (day) => SizedBox(
                                    width: 38,
                                    child: Text(
                                      day,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: MemoriaTokens.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        // Days Matrix Grid
                        _buildDaysMatrix(dateMap),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Daily Log Timeline Section (for selected date)
                  _buildDailyLogSection(selectedDayExposures),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDaysMatrix(Map<String, List<Polaroid>> dateMap) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0, Monday = 1...

    final totalCells = ((startingWeekday + daysInMonth) / 7).ceil() * 7;
    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 6,
        childAspectRatio: 0.70,
      ),
      itemBuilder: (context, index) {
        if (index < startingWeekday || index >= startingWeekday + daysInMonth) {
          // Empty cell outside current month
          return const SizedBox.shrink();
        }

        final dayNum = index - startingWeekday + 1;
        final cellDate = DateTime(year, month, dayNum);
        final dateKey = _formatDateKey(cellDate);
        final exposures = dateMap[dateKey] ?? [];
        final hasExposures = exposures.isNotEmpty;
        final isSelected = _selectedDate != null &&
            _selectedDate!.year == cellDate.year &&
            _selectedDate!.month == cellDate.month &&
            _selectedDate!.day == cellDate.day;
        final isToday = now.year == cellDate.year &&
            now.month == cellDate.month &&
            now.day == cellDate.day;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedDate = cellDate;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? MemoriaTokens.primaryContainer.withValues(alpha: 0.5)
                  : (hasExposures ? MemoriaTokens.surfaceContainerLow : Colors.transparent),
              borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
              border: Border.all(
                color: isSelected
                    ? MemoriaTokens.primary
                    : (isToday ? MemoriaTokens.outlineVariant : Colors.transparent),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Day Number
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasExposures || isToday ? FontWeight.bold : FontWeight.w500,
                    color: isToday
                        ? MemoriaTokens.primary
                        : (hasExposures ? MemoriaTokens.onSurface : MemoriaTokens.onSurfaceVariant),
                  ),
                ),

                // Mini Polaroid Tile if exposures exist
                if (hasExposures)
                  Flexible(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        Transform.rotate(
                          angle: (dayNum % 2 == 0) ? 0.03 : -0.03,
                          child: Container(
                            width: 27,
                            height: 33,
                            padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: const Color(0xFFE8E4DF), width: 0.8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: File(exposures.first.imagePath).existsSync()
                                  ? Image.file(File(exposures.first.imagePath), fit: BoxFit.cover)
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        // Badge Count
                        if (exposures.length > 1)
                          Positioned(
                            right: -3,
                            bottom: -3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: MemoriaTokens.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${exposures.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyLogSection(List<Polaroid> exposures) {
    final dateStr = _selectedDate != null ? _formatFullDate(_selectedDate!) : '';

    return Container(
      decoration: BoxDecoration(
        color: MemoriaTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MemoriaTokens.radiusLg),
        border: Border.all(color: MemoriaTokens.polaroidBorder),
        boxShadow: MemoriaTokens.shadowLevel1,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.bookOpen, color: MemoriaTokens.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Log • $dateStr',
                    style: MemoriaTokens.headlineSm(),
                  ),
                ],
              ),
              Text(
                '${exposures.length} Film${exposures.length == 1 ? '' : 's'}',
                style: MemoriaTokens.labelSm(color: MemoriaTokens.primary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (exposures.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(LucideIcons.camera, size: 36, color: MemoriaTokens.outline),
                    const SizedBox(height: 8),
                    Text(
                      'No physical exposures on this date.',
                      style: MemoriaTokens.bodyMd(color: MemoriaTokens.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the shutter anytime to record an authentic memory.',
                      style: MemoriaTokens.bodySm(),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exposures.length,
              separatorBuilder: (_, _) => const Divider(
                color: MemoriaTokens.surfaceContainerHigh,
                height: 16,
              ),
              itemBuilder: (context, index) {
                final p = exposures[index];
                final time = p.createdAt.toLocal();
                final timeStr =
                    '${time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour)}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';

                return InkWell(
                  onTap: () {
                    context.push('/polaroid/${p.id}', extra: p);
                  },
                  borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        // Mini Tilted Polaroid Thumbnail
                        Transform.rotate(
                          angle: -0.02,
                          child: Container(
                            width: 52,
                            height: 60,
                            padding: const EdgeInsets.fromLTRB(3, 3, 3, 6),
                            decoration: BoxDecoration(
                              color: MemoriaTokens.polaroidCard,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: MemoriaTokens.polaroidBorder),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              clipBehavior: Clip.antiAlias,
                               child: File(p.imagePath).existsSync()
                                  ? Image.file(File(p.imagePath), fit: BoxFit.cover)
                                  : const Icon(LucideIcons.imageOff, size: 20),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Word & Transliteration
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.selectedWord,
                                style: MemoriaTokens.headlineSm(color: MemoriaTokens.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.secondaryScript ?? ""} · ${p.transliteration ?? ""}',
                                style: MemoriaTokens.bodySm(),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$timeStr • ${p.languageCode.toUpperCase()}',
                                style: MemoriaTokens.telemetryMono(fontSize: 9),
                              ),
                            ],
                          ),
                        ),

                        // Audio button & Chevron
                        IconButton(
                          icon: const Icon(LucideIcons.volume2, size: 20, color: MemoriaTokens.primary),
                          onPressed: () {
                            _ttsService.speak(
                              languageCode: p.languageCode,
                              targetWord: p.selectedWord,
                              secondaryScript: p.secondaryScript,
                              transliteration: p.transliteration,
                            );
                          },
                        ),
                        const Icon(LucideIcons.chevronRight, size: 18, color: MemoriaTokens.outline),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
