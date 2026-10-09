import 'dart:typed_data';
import '../../core/languages/language_profile.dart';
import '../models/analysis_result.dart';

abstract class VisionService {
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    required LanguageProfile language,
  });
}
