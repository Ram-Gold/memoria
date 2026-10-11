import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/domain/models/polaroid.dart';
import 'package:memoria/domain/models/polaroid_format.dart';

void main() {
  group('PolaroidFormat Resolution Tests', () {
    test('resolves standard aspect ratio IDs correctly', () {
      expect(PolaroidFormat.fromId('1:1'), equals(PolaroidFormat.square));
      expect(PolaroidFormat.fromId('3:4'), equals(PolaroidFormat.portrait));
      expect(PolaroidFormat.fromId('4:3'), equals(PolaroidFormat.landscape));
    });

    test('resolves format enum names case-insensitively', () {
      expect(PolaroidFormat.fromId('square'), equals(PolaroidFormat.square));
      expect(PolaroidFormat.fromId('PORTRAIT'), equals(PolaroidFormat.portrait));
      expect(PolaroidFormat.fromId('Landscape'), equals(PolaroidFormat.landscape));
    });

    test('falls back to square for legacy classic or unknown values', () {
      expect(PolaroidFormat.fromId('classic'), equals(PolaroidFormat.square));
      expect(PolaroidFormat.fromId('unknown'), equals(PolaroidFormat.square));
      expect(PolaroidFormat.fromId(''), equals(PolaroidFormat.square));
    });

    test('verifies ratios match authentic polaroid specifications', () {
      expect(PolaroidFormat.square.ratio, closeTo(1.0, 0.001));
      expect(PolaroidFormat.portrait.ratio, closeTo(3.0 / 4.0, 0.001));
      expect(PolaroidFormat.landscape.ratio, closeTo(4.0 / 3.0, 0.001));
    });
  });

  group('Polaroid Model Dynamic Format Persistence Tests', () {
    test('defaults to classic layoutId and square format when omitted', () {
      final p = Polaroid(
        id: 'pol_1',
        imagePath: '/path/1.jpg',
        outputImagePath: '/path/1.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj_1',
        selectedWord: '猫',
        labelEn: 'Cat',
        createdAt: DateTime.now(),
      );

      expect(p.layoutId, equals('classic'));
      expect(p.format, equals(PolaroidFormat.square));
    });

    test('stores 3:4 Mini portrait format and resolves format getter', () {
      final p = Polaroid(
        id: 'pol_2',
        imagePath: '/path/2.jpg',
        outputImagePath: '/path/2.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj_1',
        selectedWord: '猫',
        labelEn: 'Cat',
        layoutId: '3:4',
        createdAt: DateTime.now(),
      );

      expect(p.layoutId, equals('3:4'));
      expect(p.format, equals(PolaroidFormat.portrait));
      expect(p.format.ratio, closeTo(0.75, 0.001));
    });

    test('stores 4:3 Wide landscape format and resolves format getter', () {
      final p = Polaroid(
        id: 'pol_3',
        imagePath: '/path/3.jpg',
        outputImagePath: '/path/3.jpg',
        languageCode: 'ja',
        selectedObjectId: 'obj_1',
        selectedWord: '猫',
        labelEn: 'Cat',
        layoutId: '4:3',
        createdAt: DateTime.now(),
      );

      expect(p.layoutId, equals('4:3'));
      expect(p.format, equals(PolaroidFormat.landscape));
      expect(p.format.ratio, closeTo(1.333, 0.001));
    });

    test('serializes and deserializes layout_id to and from DB map', () {
      final p = Polaroid(
        id: 'pol_db_1',
        imagePath: '/path/img.jpg',
        outputImagePath: '/path/img.jpg',
        languageCode: 'fil',
        selectedObjectId: 'obj_fil',
        selectedWord: 'aklat',
        labelEn: 'Book',
        layoutId: '3:4',
        createdAt: DateTime.parse('2026-10-11T12:00:00Z'),
      );

      final dbMap = p.toDbMap();
      expect(dbMap['layout_id'], equals('3:4'));

      final restored = Polaroid.fromDbMap(dbMap);
      expect(restored.layoutId, equals('3:4'));
      expect(restored.format, equals(PolaroidFormat.portrait));
    });

    test('deserializes legacy DB record without layout_id gracefully', () {
      final legacyDbMap = {
        'id': 'pol_legacy',
        'image_path': '/path/leg.jpg',
        'output_image_path': '/path/leg.jpg',
        'language_code': 'ja',
        'selected_object_id': 'obj_leg',
        'selected_word': '本',
        'label_en': 'Book',
        'layout_id': 'classic',
        'created_at': '2026-09-01T10:00:00Z',
      };

      final restored = Polaroid.fromDbMap(legacyDbMap);
      expect(restored.layoutId, equals('classic'));
      expect(restored.format, equals(PolaroidFormat.square));
    });
  });
}
