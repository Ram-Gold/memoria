import 'package:flutter/material.dart';
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
        final String imagePath;
        final String? layoutId;
        final Future<String>? croppedFuture;
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          imagePath = map['imagePath'] as String? ?? '';
          layoutId = map['layoutId'] as String?;
          croppedFuture = map['croppedFuture'] as Future<String>?;
        } else {
          imagePath = state.extra as String? ?? '';
          layoutId = null;
          croppedFuture = null;
        }
        return DevelopScreen(
          imagePath: imagePath,
          layoutId: layoutId,
          croppedFuture: croppedFuture,
        );
      },
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final imagePath = extra['imagePath'] as String? ?? '';
        final layoutId = extra['layoutId'] as String?;
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
          layoutId: layoutId,
        );
      },
    ),
    GoRoute(
      path: '/polaroid/:id',
      pageBuilder: (context, state) {
        final polaroid = state.extra as Polaroid;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: PolaroidDetailScreen(polaroid: polaroid),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: child,
            );
          },
        );
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
