import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
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

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          // Tactile Editorial Analog pill capsule
          child: Container(
            decoration: BoxDecoration(
              color: MemoriaTokens.cameraObsidian, // Deep camera-body matte obsidian
              borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
              boxShadow: MemoriaTokens.shadowCapsule,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: GNav(
              rippleColor: Colors.white24,
              hoverColor: Colors.white12,
              haptic: true,
              tabBorderRadius: 28,
              curve: Curves.easeOutExpo,
              duration: const Duration(milliseconds: 350),
              gap: 8,
              color: Colors.white60,
              activeColor: Colors.white,
              iconSize: 22,
              tabBackgroundColor: MemoriaTokens.primary, // Terracotta orange accent
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              selectedIndex: currentIndex,
              onTabChange: (index) {
                ref.read(navigationIndexProvider.notifier).state = index;
              },
              tabs: const [
                GButton(
                  icon: Icons.camera_alt_outlined,
                  text: 'Camera',
                ),
                GButton(
                  icon: Icons.calendar_month_outlined,
                  text: 'Calendar',
                ),
                GButton(
                  icon: Icons.photo_library_outlined,
                  text: 'Scrapbook',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


