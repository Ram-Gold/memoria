import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/animations/polaroid_flight_shuttle.dart';

void main() {
  group('PolaroidFlightShuttle Tests', () {
    testWidgets('builds flight shuttle during Hero push transition', (tester) async {
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 450),
      );

      final fromHeroKey = GlobalKey();
      final toHeroKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Hero(
                  key: fromHeroKey,
                  tag: 'test_hero',
                  child: Container(
                    width: 146,
                    height: 180,
                    color: Colors.amber,
                  ),
                ),
                Hero(
                  key: toHeroKey,
                  tag: 'test_hero_dest',
                  child: Container(
                    width: 320,
                    height: 380,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final fromContext = fromHeroKey.currentContext!;
      final toContext = toHeroKey.currentContext!;

      // Build shuttle at halfway progress t=0.5
      animationController.value = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PolaroidFlightShuttle.buildShuttle(
                animation: animationController,
                flightDirection: HeroFlightDirection.push,
                fromHeroContext: fromContext,
                toHeroContext: toContext,
                sourceAngle: -0.015,
                targetAngle: 0.015,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PolaroidFlightShuttle), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
      expect(find.byType(Material), findsWidgets);

      animationController.dispose();
    });

    testWidgets('builds flight shuttle during Hero pop transition', (tester) async {
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 400),
      );

      final fromHeroKey = GlobalKey();
      final toHeroKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Hero(
                  key: fromHeroKey,
                  tag: 'test_hero',
                  child: const SizedBox(width: 320, height: 380),
                ),
                Hero(
                  key: toHeroKey,
                  tag: 'test_hero_dest',
                  child: const SizedBox(width: 146, height: 180),
                ),
              ],
            ),
          ),
        ),
      );

      final fromContext = fromHeroKey.currentContext!;
      final toContext = toHeroKey.currentContext!;

      animationController.value = 0.2;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PolaroidFlightShuttle.buildShuttle(
                animation: animationController,
                flightDirection: HeroFlightDirection.pop,
                fromHeroContext: fromContext,
                toHeroContext: toContext,
                sourceAngle: 0.015,
                targetAngle: -0.015,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PolaroidFlightShuttle), findsOneWidget);

      animationController.dispose();
    });

    testWidgets('does not throw RenderFlex overflow in tight intermediate constraints', (tester) async {
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 450),
      );

      final fromHeroKey = GlobalKey();
      final toHeroKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Hero(
                  key: fromHeroKey,
                  tag: 'test_tight_source',
                  child: const SizedBox(width: 136.2, height: 156.0),
                ),
                Hero(
                  key: toHeroKey,
                  tag: 'test_tight_dest',
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.33,
                          child: Container(color: Colors.grey),
                        ),
                        Container(
                          constraints: const BoxConstraints(minHeight: 64),
                          child: const Text('Chin text sample'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final fromContext = fromHeroKey.currentContext!;
      final toContext = toHeroKey.currentContext!;

      // Simulate start of flight at tight thumbnail bounds
      animationController.value = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 136.2,
              height: 156.0,
              child: PolaroidFlightShuttle.buildShuttle(
                animation: animationController,
                flightDirection: HeroFlightDirection.push,
                fromHeroContext: fromContext,
                toHeroContext: toContext,
                sourceAngle: -0.015,
                targetAngle: 0.015,
              ),
            ),
          ),
        ),
      );

      // Verify no exceptions were caught and shuttle is rendered cleanly
      expect(tester.takeException(), isNull);
      expect(find.byType(PolaroidFlightShuttle), findsOneWidget);

      animationController.dispose();
    });
  });
}

