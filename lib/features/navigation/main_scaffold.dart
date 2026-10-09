import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../calendar/calendar_screen.dart';
import '../capture/camera_screen.dart';
import '../gallery/scrapbook_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CameraScreen(),
    CalendarScreen(),
    ScrapbookScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          // Tactile Editorial Analog pill capsule
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1918), // Deep camera-body matte obsidian
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
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
              tabBackgroundColor: const Color(0xFFE36528), // Terracotta orange accent
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                });
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

