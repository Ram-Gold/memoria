import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/core/languages/language_profile.dart';
import 'package:memoria/data/services/mock_vision_service.dart';
import 'package:memoria/domain/models/analysis_result.dart';
import 'package:memoria/domain/models/detected_object.dart';
import 'package:memoria/domain/models/polaroid.dart';
import 'package:memoria/features/editor/editor_screen.dart';
import 'package:memoria/features/gallery/polaroid_detail_screen.dart';

void main() {
  group('DetectedObject Confidence Tests', () {
    test('defaults to 1.0 confidence when omitted', () {
      const obj = DetectedObject(
        id: 'obj_1',
        labelEn: 'Cup',
        targetWord: 'コップ',
        box: [0, 0, 500, 500],
      );
      expect(obj.confidence, 1.0);
      expect(obj.isConfident(), isTrue);
      expect(obj.confidencePercentage, 100);
    });

    test('isConfident evaluates against default threshold (0.60)', () {
      const highConfObj = DetectedObject(
        id: 'obj_high',
        labelEn: 'Book',
        targetWord: '本',
        confidence: 0.85,
        box: [0, 0, 500, 500],
      );
      const lowConfObj = DetectedObject(
        id: 'obj_low',
        labelEn: 'Desk',
        targetWord: '机',
        confidence: 0.52,
        box: [0, 0, 500, 500],
      );

      expect(highConfObj.isConfident(), isTrue);
      expect(highConfObj.confidencePercentage, 85);

      expect(lowConfObj.isConfident(), isFalse);
      expect(lowConfObj.confidencePercentage, 52);
    });

    test('fromJson handles confidence, confidence_score, and normalization', () {
      final json1 = {
        'id': 'obj_1',
        'label_en': 'Cat',
        'target_word': '猫',
        'confidence': 0.92,
        'box_2d': [10, 20, 30, 40],
      };
      final obj1 = DetectedObject.fromJson(json1);
      expect(obj1.confidence, 0.92);

      // Alternative naming: confidence_score
      final json2 = {
        'id': 'obj_2',
        'label_en': 'Dog',
        'target_word': '犬',
        'confidence_score': 0.78,
      };
      final obj2 = DetectedObject.fromJson(json2);
      expect(obj2.confidence, 0.78);

      // Percentage scale: 85 -> 0.85
      final json3 = {
        'id': 'obj_3',
        'label_en': 'Bird',
        'target_word': '鳥',
        'confidenciality_score': 85.0,
      };
      final obj3 = DetectedObject.fromJson(json3);
      expect(obj3.confidence, closeTo(0.85, 0.001));
    });

    test('serialization toDbMap and fromDbMap preserves confidence', () {
      const obj = DetectedObject(
        id: 'obj_db',
        labelEn: 'Plant',
        targetWord: '観葉植物',
        confidence: 0.73,
        box: [100, 200, 300, 400],
      );

      final dbMap = obj.toDbMap('pol_123');
      expect(dbMap['confidence'], 0.73);

      final reconstructed = DetectedObject.fromDbMap(dbMap);
      expect(reconstructed.confidence, 0.73);
      expect(reconstructed.id, 'obj_db');
    });
  });

  group('AnalysisResult Confident Objects Tests', () {
    test('confidentObjects filters out items below threshold', () {
      const result = AnalysisResult(
        sessionId: 'test_session',
        languageCode: 'ja',
        primaryObjectId: 'obj_1',
        sceneDescription: 'Test scene',
        detectedObjects: [
          DetectedObject(
            id: 'obj_1',
            labelEn: 'Mug',
            targetWord: '珈琲碗',
            confidence: 0.95,
            box: [0, 0, 100, 100],
          ),
          DetectedObject(
            id: 'obj_2',
            labelEn: 'Book',
            targetWord: '本',
            confidence: 0.88,
            box: [0, 0, 100, 100],
          ),
          DetectedObject(
            id: 'obj_3',
            labelEn: 'Desk',
            targetWord: '机',
            confidence: 0.45, // Below 0.60 threshold
            box: [0, 0, 100, 100],
          ),
        ],
      );

      expect(result.detectedObjects.length, 3);
      expect(result.confidentObjects.length, 2);
      expect(result.confidentObjects.map((o) => o.id), containsAll(['obj_1', 'obj_2']));
      expect(result.confidentObjects.map((o) => o.id), isNot(contains('obj_3')));
    });

    test('primaryObject prefers confident primary object or fallback confident object', () {
      // Primary is below threshold, second is above threshold
      const result = AnalysisResult(
        sessionId: 'test_session',
        languageCode: 'ja',
        primaryObjectId: 'obj_low',
        sceneDescription: 'Test scene',
        detectedObjects: [
          DetectedObject(
            id: 'obj_low',
            labelEn: 'Low Confidence Item',
            targetWord: '低い',
            confidence: 0.30,
            box: [0, 0, 100, 100],
          ),
          DetectedObject(
            id: 'obj_high',
            labelEn: 'Confident Item',
            targetWord: '高い',
            confidence: 0.90,
            box: [0, 0, 100, 100],
          ),
        ],
      );

      // Should automatically select obj_high as the primary focal object
      expect(result.primaryObject?.id, 'obj_high');
    });
  });

  group('VisionService Mock Confidence Output Tests', () {
    test('MockVisionService produces objects with calibrated confidence scores', () async {
      final service = MockVisionService();
      final result = await service.analyze(
        imageBytes: Uint8List(16),
        language: LanguageRegistry.japanese,
      );

      expect(result.detectedObjects, isNotEmpty);
      for (final obj in result.detectedObjects) {
        expect(obj.confidence, inInclusiveRange(0.0, 1.0));
      }

      // At least one object meets threshold and serves as primary
      expect(result.confidentObjects, isNotEmpty);
      expect(result.primaryObject!.isConfident(), isTrue);
    });
  });

  group('UI Filtering Tests (Switch Taught Object & All Objects in Memory)', () {
    testWidgets('EditorScreen does NOT display objects that fail confidence threshold',
        (tester) async {
      const analysisResult = AnalysisResult(
        sessionId: 'sess_1',
        languageCode: 'ja',
        primaryObjectId: 'obj_high_1',
        sceneDescription: 'Test room',
        detectedObjects: [
          DetectedObject(
            id: 'obj_high_1',
            labelEn: 'Coffee Mug',
            targetWord: '珈琲碗',
            secondaryScript: 'コーヒーカップ',
            transliteration: 'koohii kappu',
            confidence: 0.95,
            box: [0, 0, 500, 500],
          ),
          DetectedObject(
            id: 'obj_high_2',
            labelEn: 'Open Book',
            targetWord: '本',
            secondaryScript: 'ほん',
            transliteration: 'hon',
            confidence: 0.85,
            box: [0, 0, 500, 500],
          ),
          DetectedObject(
            id: 'obj_low_unconfident',
            labelEn: 'Blurry Shadow',
            targetWord: '影',
            secondaryScript: 'かげ',
            transliteration: 'kage',
            confidence: 0.42, // Below 0.60 threshold
            box: [0, 0, 500, 500],
          ),
        ],
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditorScreen(
              imagePath: '/tmp/test.jpg',
              analysisResult: analysisResult,
            ),
          ),
        ),
      );

      // Verify that the Switch Taught Object section is rendered
      expect(find.text('Switch Taught Object in Scene:'), findsOneWidget);

      // Confident objects MUST be visible
      expect(find.text('珈琲碗 (Coffee Mug)'), findsOneWidget);
      expect(find.text('本 (Open Book)'), findsOneWidget);
      expect(find.text('95% confident'), findsOneWidget);
      expect(find.text('85% confident'), findsOneWidget);

      // Low confidence object MUST NOT appear in Switch Taught Object in Scene
      expect(find.text('影 (Blurry Shadow)'), findsNothing);
      expect(find.text('42% confident'), findsNothing);
    });

    testWidgets('PolaroidDetailScreen does NOT display objects that fail confidence threshold in All Objects',
        (tester) async {
      final polaroid = Polaroid(
        id: 'pol_detail_test',
        imagePath: '/tmp/test.jpg',
        outputImagePath: '/tmp/test.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj_high_1',
        selectedWord: '珈琲碗',
        secondaryScript: 'コーヒーカップ',
        transliteration: 'koohii kappu',
        createdAt: DateTime.now(),
        detectedObjects: const [
          DetectedObject(
            id: 'obj_high_1',
            labelEn: 'Coffee Mug',
            targetWord: '珈琲碗',
            secondaryScript: 'コーヒーカップ',
            transliteration: 'koohii kappu',
            confidence: 0.95,
            box: [0, 0, 500, 500],
          ),
          DetectedObject(
            id: 'obj_low_unconfident',
            labelEn: 'Uncertain Table',
            targetWord: '机',
            secondaryScript: 'つくえ',
            transliteration: 'tsukue',
            confidence: 0.38, // Below 0.60 threshold
            box: [0, 0, 500, 500],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PolaroidDetailScreen(
              polaroid: polaroid,
            ),
          ),
        ),
      );

      // Verify header is present
      expect(find.text('All Objects in this Memory:'), findsOneWidget);

      // Confident object is shown
      expect(find.text('珈琲碗 (Coffee Mug)'), findsOneWidget);
      expect(find.text('95% match'), findsOneWidget);

      // Object that does NOT reach the threshold does NOT appear!
      expect(find.text('机 (Uncertain Table)'), findsNothing);
      expect(find.text('38% match'), findsNothing);
    });
  });
}
