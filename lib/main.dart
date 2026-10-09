import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/memoria_theme.dart';
import 'app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file (using mock fallback): $e');
  }

  runApp(
    const ProviderScope(
      child: MemoriaApp(),
    ),
  );
}

class MemoriaApp extends StatelessWidget {
  const MemoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Memoria',
      debugShowCheckedModeBanner: false,
      theme: MemoriaTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

