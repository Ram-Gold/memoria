import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/main.dart';

void main() {
  testWidgets('Memoria app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MemoriaApp(),
      ),
    );

    // Verify main screen renders without error
    expect(find.byType(MemoriaApp), findsOneWidget);
  });
}
