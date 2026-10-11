import 'package:flutter_brands/flutter_brands.dart';

enum AiEngineMode {
  local,
  cloud,
}

enum AiCloudProvider {
  gemini(
    id: 'gemini',
    displayName: 'Google Gemini',
    defaultModel: 'gemini-2.0-flash',
    description: 'Gemini 2.0 Flash • Ultra-fast, 258 image tokens flat, free tier',
    brandIcon: BrandIcons.gemini,
    envKeyName: 'GEMINI_API_KEY',
    consoleUrl: 'https://aistudio.google.com/app/apikey',
  );

  final String id;
  final String displayName;
  final String defaultModel;
  final String description;
  final BrandIconData brandIcon;
  final String envKeyName;
  final String consoleUrl;

  const AiCloudProvider({
    required this.id,
    required this.displayName,
    required this.defaultModel,
    required this.description,
    required this.brandIcon,
    required this.envKeyName,
    required this.consoleUrl,
  });

  static AiCloudProvider fromId(String id) {
    return AiCloudProvider.values.firstWhere(
      (p) => p.id == id,
      orElse: () => AiCloudProvider.gemini,
    );
  }
}
