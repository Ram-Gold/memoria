import 'package:flutter_brands/flutter_brands.dart';

enum AiEngineMode {
  local,
  cloud,
}

enum AiCloudProvider {
  mistral(
    id: 'mistral',
    displayName: 'Mistral AI',
    defaultModel: 'pixtral-12b-2409',
    description: 'Pixtral 12B Vision • Default pedagogical engine',
    brandIcon: BrandIcons.mistral,
    envKeyName: 'MISTRAL_API_KEY',
    consoleUrl: 'https://console.mistral.ai/api-keys/',
  ),
  openai(
    id: 'openai',
    displayName: 'OpenAI',
    defaultModel: 'gpt-4o-mini',
    description: 'GPT-4o-mini • High accuracy structured multimodal vision',
    brandIcon: BrandIcons.openai,
    envKeyName: 'OPENAI_API_KEY',
    consoleUrl: 'https://platform.openai.com/api-keys',
  ),
  gemini(
    id: 'gemini',
    displayName: 'Google Gemini',
    defaultModel: 'gemini-1.5-flash',
    description: 'Gemini 1.5 Flash • Ultra-fast multimodal reasoning',
    brandIcon: BrandIcons.gemini,
    envKeyName: 'GEMINI_API_KEY',
    consoleUrl: 'https://aistudio.google.com/app/apikey',
  ),
  claude(
    id: 'claude',
    displayName: 'Anthropic Claude',
    defaultModel: 'claude-3-5-haiku-20241022',
    description: 'Claude 3.5 Haiku • Nuanced linguistic & cultural vision',
    brandIcon: BrandIcons.claude,
    envKeyName: 'CLAUDE_API_KEY',
    consoleUrl: 'https://console.anthropic.com/settings/keys',
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
      orElse: () => AiCloudProvider.mistral,
    );
  }
}
