import 'package:go_router/go_router.dart';
import '../domain/models/analysis_result.dart';
import '../domain/models/polaroid.dart';
import '../features/develop/develop_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/gallery/collection_album_screen.dart';
import '../features/gallery/polaroid_detail_screen.dart';
import '../features/navigation/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScaffold(),
    ),
    GoRoute(
      path: '/develop',
      builder: (context, state) {
        final imagePath = state.extra as String? ?? '';
        return DevelopScreen(imagePath: imagePath);
      },
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final imagePath = extra['imagePath'] as String? ?? '';
        final analysisResult = extra['analysisResult'] as AnalysisResult? ??
            const AnalysisResult(
              sessionId: 'empty',
              languageCode: 'ja',
              primaryObjectId: 'none',
              sceneDescription: '',
              detectedObjects: [],
            );
        return EditorScreen(
          imagePath: imagePath,
          analysisResult: analysisResult,
        );
      },
    ),
    GoRoute(
      path: '/polaroid/:id',
      builder: (context, state) {
        final polaroid = state.extra as Polaroid;
        return PolaroidDetailScreen(polaroid: polaroid);
      },
    ),
    GoRoute(
      path: '/collection/:languageCode',
      builder: (context, state) {
        final languageCode = state.pathParameters['languageCode'] ?? 'ja';
        return CollectionAlbumScreen(languageCode: languageCode);
      },
    ),
  ],
);
