import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          // Unstyled 3-tab bottom capsule layout
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.camera_alt, 'Camera'),
                _buildNavItem(1, Icons.calendar_month, 'Calendar'),
                _buildNavItem(2, Icons.photo_library, 'Scrapbook'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.orange : Colors.white60,
      ),
      tooltip: label,
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}
