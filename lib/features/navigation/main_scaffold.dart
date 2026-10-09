import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../core/theme/memoria_tokens.dart';
import '../calendar/calendar_screen.dart';
import '../capture/camera_screen.dart';
import '../gallery/scrapbook_screen.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  final List<Widget> _screens = const [
    CameraScreen(),
    CalendarScreen(),
    ScrapbookScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isCamera = currentIndex == 0;

    final backgroundColor = switch (currentIndex) {
      0 => Colors.black,
      2 => MemoriaTokens.surfaceContainerLow,
      _ => MemoriaTokens.surface,
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isCamera
            ? Brightness.light
            : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isCamera ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: backgroundColor,
        body: IndexedStack(index: currentIndex, children: _screens),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 58.0,
              vertical: 10.0,
            ),
            // Tactile Editorial Analog pill capsule
            child: Container(
              decoration: BoxDecoration(
                color: MemoriaTokens
                    .cameraObsidian, // Deep camera-body matte obsidian
                borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                boxShadow: MemoriaTokens.shadowCapsule,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 7.0,
              ),
              child: GNav(
                rippleColor: Colors.white24,
                hoverColor: Colors.white12,
                haptic: true,
                tabBorderRadius: 28,
                curve: Curves.easeOutCubic,
                duration: const Duration(milliseconds: 180),
                gap: 8,
                color: Colors.white60,
                activeColor: Colors.white,
                iconSize: 21,
                tabBackgroundColor:
                    MemoriaTokens.primary, // Terracotta orange accent
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                selectedIndex: currentIndex,
                onTabChange: (index) {
                  ref.read(navigationIndexProvider.notifier).state = index;
                },
                tabs: const [
                  GButton(icon: LucideIcons.camera, text: 'Camera'),
                  GButton(icon: LucideIcons.calendarDays, text: 'Calendar'),
                  GButton(icon: LucideIcons.images, text: 'Scrapbook'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
