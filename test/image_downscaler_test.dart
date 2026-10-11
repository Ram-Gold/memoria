import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memoria/core/utils/image_downscaler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageDownscaler Tests', () {
    test('downscales wide image to maxDimension 768 while preserving aspect ratio', () async {
      // Create a 2000 x 1000 test image (2:1 aspect ratio)
      final original = img.Image(width: 2000, height: 1000);
      img.fill(original, color: img.ColorRgb8(255, 0, 0));
      final originalBytes = Uint8List.fromList(img.encodeJpg(original, quality: 90));

      final downscaledBytes = await ImageDownscaler.downscaleBytes(
        originalBytes,
        maxDimension: 768,
        quality: 80,
      );

      final decoded = img.decodeImage(downscaledBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 768);
      expect(decoded.height, 384);
      expect(downscaledBytes.lengthInBytes, lessThan(originalBytes.lengthInBytes));
    });

    test('downscales tall portrait image to maxDimension 768', () async {
      // Create a 1200 x 2400 test image (1:2 aspect ratio)
      final original = img.Image(width: 1200, height: 2400);
      img.fill(original, color: img.ColorRgb8(0, 255, 0));
      final originalBytes = Uint8List.fromList(img.encodeJpg(original, quality: 90));

      final downscaledBytes = await ImageDownscaler.downscaleBytes(
        originalBytes,
        maxDimension: 768,
        quality: 80,
      );

      final decoded = img.decodeImage(downscaledBytes);
      expect(decoded, isNotNull);
      expect(decoded!.height, 768);
      expect(decoded.width, 384);
    });

    test('preserves already small image without expanding', () async {
      // Create a 400 x 300 test image
      final original = img.Image(width: 400, height: 300);
      img.fill(original, color: img.ColorRgb8(0, 0, 255));
      final originalBytes = Uint8List.fromList(img.encodeJpg(original, quality: 80));

      final downscaledBytes = await ImageDownscaler.downscaleBytes(
        originalBytes,
        maxDimension: 768,
      );

      final decoded = img.decodeImage(downscaledBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 400);
      expect(decoded.height, 300);
    });
  });
}
