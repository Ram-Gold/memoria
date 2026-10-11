import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Background isolate worker payload
class _DownscaleParams {
  final Uint8List rawBytes;
  final int maxDimension;
  final int quality;

  _DownscaleParams(this.rawBytes, this.maxDimension, this.quality);
}

/// High-performance client-side image downscaler running in a background isolate.
/// 
/// Shrinks modern high-resolution smartphone camera captures (12MP–48MP / 4MB–15MB)
/// down to ~768px long-edge JPEGs (~60KB–120KB).
/// 
/// This delivers a ~99% payload reduction before base64 encoding and cloud transmission,
/// preventing mobile OOMs and dramatically reducing network latency and token usage.
class ImageDownscaler {
  static const int defaultMaxDimension = 768;
  static const int defaultQuality = 80;

  /// Downscale raw image bytes in a background isolate.
  static Future<Uint8List> downscaleBytes(
    Uint8List rawBytes, {
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) async {
    final stopwatch = Stopwatch()..start();
    final originalLength = rawBytes.lengthInBytes;

    try {
      final result = await compute(
        _downscaleWorker,
        _DownscaleParams(rawBytes, maxDimension, quality),
      );
      stopwatch.stop();

      developer.log(
        'Downscaled image: ${(originalLength / 1024).toStringAsFixed(1)}KB -> '
        '${(result.lengthInBytes / 1024).toStringAsFixed(1)}KB '
        'in ${stopwatch.elapsedMilliseconds}ms',
        name: 'ImageDownscaler',
      );

      return result;
    } catch (e) {
      developer.log('Error downscaling image in isolate: $e. Falling back to original bytes.', name: 'ImageDownscaler');
      return rawBytes;
    }
  }

  /// Read and downscale an image file from disk path in a background isolate.
  static Future<Uint8List> downscaleFile(
    String filePath, {
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found for downscaling', filePath);
    }
    final bytes = await file.readAsBytes();
    return downscaleBytes(bytes, maxDimension: maxDimension, quality: quality);
  }

  /// Top-level worker executed in background isolate via compute()
  static Uint8List _downscaleWorker(_DownscaleParams params) {
    final decoded = img.decodeImage(params.rawBytes);
    if (decoded == null) {
      return params.rawBytes;
    }

    final origW = decoded.width;
    final origH = decoded.height;

    // Check if downscaling is needed
    if (origW <= params.maxDimension && origH <= params.maxDimension) {
      return Uint8List.fromList(img.encodeJpg(decoded, quality: params.quality));
    }

    int targetW;
    int targetH;

    if (origW >= origH) {
      targetW = params.maxDimension;
      targetH = (origH * params.maxDimension / origW).round();
    } else {
      targetH = params.maxDimension;
      targetW = (origW * params.maxDimension / origH).round();
    }

    final resized = img.copyResize(
      decoded,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.linear,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: params.quality));
  }
}
