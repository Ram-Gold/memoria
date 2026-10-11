import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/memoria_tokens.dart';
import '../calendar/calendar_screen.dart';
import '../capture/camera_screen.dart';
import '../gallery/scrapbook_screen.dart';
import 'memoria_floating_nav_bar.dart';

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
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // 1. Fullscreen body with IndexedStack
            Positioned.fill(
              child: IndexedStack(
                index: currentIndex,
                children: _screens,
              ),
            ),

            // 2. Floating Tactile Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Center(
                    child: MemoriaFloatingNavBar(
                      selectedIndex: currentIndex,
                      onTabSelected: (index) {
                        ref.read(navigationIndexProvider.notifier).state = index;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
