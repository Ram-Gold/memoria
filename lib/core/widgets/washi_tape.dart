import 'package:flutter/material.dart';

/// Translucent decorative washi tape strip with realistic bevel and organic tilt
class WashiTapeWidget extends StatelessWidget {
  final double width;
  final double height;
  final double angle;
  final Color color;

  const WashiTapeWidget({
    super.key,
    this.width = 72,
    this.height = 18,
    this.angle = -0.035, // ~ -2 degrees
    this.color = const Color(0xBFDFC0B4), // Translucent blush warm tape
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: double.infinity,
            height: 0.6,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}
