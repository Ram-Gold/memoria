import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/memoria_tokens.dart';

/// Analog Rubber Heart Ink Stamp (`#BA1A1A`)
/// Displays an authentic double-circle dashed border with a heart icon,
/// tilted at -14 degrees, with optional tap-to-favorite haptics.
class RubberStampWidget extends StatelessWidget {
  final bool isStamped;
  final VoidCallback? onTap;
  final double size;
  final double angle;

  const RubberStampWidget({
    super.key,
    required this.isStamped,
    this.onTap,
    this.size = 36,
    this.angle = -0.24, // Approx -14 degrees in radians
  });

  @override
  Widget build(BuildContext context) {
    if (!isStamped && onTap == null) {
      return const SizedBox.shrink();
    }

    Widget stamp = AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isStamped ? 0.88 : 0.25,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: MemoriaTokens.stampVermilion,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: MemoriaTokens.stampVermilion.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                isStamped ? Icons.favorite : Icons.favorite_border,
                color: MemoriaTokens.stampVermilion,
                size: size * 0.52,
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: stamp,
      );
    }

    return stamp;
  }
}
