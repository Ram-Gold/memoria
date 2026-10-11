import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/memoria_tokens.dart';

/// Tactile analog flight shuttle for Polaroid cards transitioning between
/// album grid slots and the full-screen PolaroidDetailScreen.
class PolaroidFlightShuttle extends StatelessWidget {
  final Animation<double> animation;
  final HeroFlightDirection flightDirection;
  final BuildContext fromHeroContext;
  final BuildContext toHeroContext;
  final double sourceAngle;
  final double targetAngle;

  const PolaroidFlightShuttle({
    super.key,
    required this.animation,
    required this.flightDirection,
    required this.fromHeroContext,
    required this.toHeroContext,
    this.sourceAngle = 0.0,
    this.targetAngle = 0.015,
  });

  /// Factory helper for Hero flightShuttleBuilder
  static Widget buildShuttle({
    required Animation<double> animation,
    required HeroFlightDirection flightDirection,
    required BuildContext fromHeroContext,
    required BuildContext toHeroContext,
    double sourceAngle = 0.0,
    double targetAngle = 0.015,
  }) {
    return PolaroidFlightShuttle(
      animation: animation,
      flightDirection: flightDirection,
      fromHeroContext: fromHeroContext,
      toHeroContext: toHeroContext,
      sourceAngle: sourceAngle,
      targetAngle: targetAngle,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always use the detailed destination card layout for crisp scaling
    final Hero detailHero = flightDirection == HeroFlightDirection.push
        ? toHeroContext.widget as Hero
        : fromHeroContext.widget as Hero;
    final Widget cardContent = detailHero.child;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        // Continuous smooth rotation interpolation across push (0->1) and pop (1->0)
        final currentAngle = sourceAngle + (targetAngle - sourceAngle) * t;

        // Parabolic altitude curve for tactile elevation lift (peaks at midway t=0.5)
        final altitude = math.sin(t * math.pi);
        final shadowBlur = 8.0 + (altitude * 22.0);
        final shadowSpread = altitude * 3.0;
        final shadowOffset = Offset(0, 3.0 + (altitude * 14.0));

        return Material(
          type: MaterialType.transparency,
          child: Transform.rotate(
            angle: currentAngle,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.16 + (altitude * 0.16)),
                    blurRadius: shadowBlur,
                    spreadRadius: shadowSpread,
                    offset: shadowOffset,
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: 320,
                  child: cardContent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
