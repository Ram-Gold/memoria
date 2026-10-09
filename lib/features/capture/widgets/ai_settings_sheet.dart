import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_brands/flutter_brands.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers.dart';
import '../../../core/ai/ai_settings_provider.dart';
import '../../../core/constants/ai_providers.dart';
import '../../../core/theme/memoria_tokens.dart';
import '../../../data/services/local_vlm_model_manager.dart';

class AiSettingsSheet extends ConsumerStatefulWidget {
  const AiSettingsSheet({super.key});

  @override
  ConsumerState<AiSettingsSheet> createState() => _AiSettingsSheetState();
}

class _AiSettingsSheetState extends ConsumerState<AiSettingsSheet> {
  AiCloudProvider? _editingProvider;
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _customUrlController = TextEditingController();
  final TextEditingController _hfTokenController = TextEditingController();
  bool _obscureText = true;
  bool _showCustomUrl = false;
  bool _hfTokenLoaded = false;

  @override
  void dispose() {
    _keyController.dispose();
    _customUrlController.dispose();
    _hfTokenController.dispose();
    super.dispose();
  }

  void _startEditingKey(AiCloudProvider provider, String currentKey) {
    setState(() {
      _editingProvider = provider;
      _keyController.text = currentKey;
      _obscureText = true;
    });
  }

  void _saveKey(AiCloudProvider provider) {
    final newKey = _keyController.text.trim();
    ref.read(aiApiKeysProvider.notifier).setKey(provider, newKey);
    HapticFeedback.mediumImpact();
    setState(() {
      _editingProvider = null;
    });
  }

  Future<void> _openConsole(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engineMode = ref.watch(aiEngineModeProvider);
    final selectedCloud = ref.watch(selectedCloudProviderProvider);
    final keysNotifier = ref.watch(aiApiKeysProvider.notifier);
    final vlmManager = ref.watch(localVlmModelManagerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: MemoriaTokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(MemoriaTokens.radiusXl)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Grab Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MemoriaTokens.polaroidBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Description
              Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 22,
                    color: MemoriaTokens.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vision AI Engine',
                    style: MemoriaTokens.headlineMd(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select how photographs are analyzed into authentic language-learning Polaroids.',
                style: MemoriaTokens.bodySm(),
              ),
              const SizedBox(height: 18),

              // Segmented Engine Switcher (Local vs Cloud)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MemoriaTokens.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(aiEngineModeProvider.notifier).setMode(AiEngineMode.local);
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: engineMode == AiEngineMode.local
                                ? MemoriaTokens.surfaceBright
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                            boxShadow: engineMode == AiEngineMode.local
                                ? MemoriaTokens.shadowLevel1
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.cpu,
                                size: 16,
                                color: engineMode == AiEngineMode.local
                                    ? MemoriaTokens.primaryDark
                                    : MemoriaTokens.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Local On-Device',
                                style: MemoriaTokens.labelSm(
                                  color: engineMode == AiEngineMode.local
                                      ? MemoriaTokens.primaryDark
                                      : MemoriaTokens.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(aiEngineModeProvider.notifier).setMode(AiEngineMode.cloud);
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: engineMode == AiEngineMode.cloud
                                ? MemoriaTokens.surfaceBright
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
                            boxShadow: engineMode == AiEngineMode.cloud
                                ? MemoriaTokens.shadowLevel1
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.cloud,
                                size: 16,
                                color: engineMode == AiEngineMode.cloud
                                    ? MemoriaTokens.primaryDark
                                    : MemoriaTokens.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cloud Vision (BYOK)',
                                style: MemoriaTokens.labelSm(
                                  color: engineMode == AiEngineMode.cloud
                                      ? MemoriaTokens.primaryDark
                                      : MemoriaTokens.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Local Mode Explainer Banner
              if (engineMode == AiEngineMode.local) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MemoriaTokens.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                    border: Border.all(color: MemoriaTokens.polaroidBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MemoriaTokens.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          size: 20,
                          color: MemoriaTokens.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline Gemma AI (100% Private)',
                              style: MemoriaTokens.labelMd(),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Powered by Google Gemma / PaliGemma on-device VLM for private visual language learning with zero cloud data transmission.',
                              style: MemoriaTokens.bodySm(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildVlmManagementSection(vlmManager),
              ],

              // Cloud Mode Providers Section
              if (engineMode == AiEngineMode.cloud) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CLOUD PROVIDERS (BRING YOUR OWN KEY):',
                      style: MemoriaTokens.labelSm(color: MemoriaTokens.primaryDark),
                    ),
                    Text(
                      'Mistral is default',
                      style: MemoriaTokens.labelSm(color: MemoriaTokens.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...AiCloudProvider.values.map((provider) {
                  final isSelected = provider == selectedCloud;
                  final rawKey = keysNotifier.getKey(provider);
                  final hasKey = rawKey.trim().isNotEmpty;
                  final isEditing = _editingProvider == provider;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MemoriaTokens.primaryContainer
                          : MemoriaTokens.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? MemoriaTokens.primary
                            : MemoriaTokens.polaroidBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          onTap: () {
                            ref
                                .read(selectedCloudProviderProvider.notifier)
                                .setProvider(provider);
                            HapticFeedback.selectionClick();
                          },
                          leading: Container(
                            width: 38,
                            height: 38,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: MemoriaTokens.surfaceBright,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: MemoriaTokens.polaroidBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: BrandIcon(
                                provider.brandIcon,
                                width: 22,
                                height: 22,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                provider.displayName,
                                style: MemoriaTokens.labelMd(),
                              ),
                              if (provider == AiCloudProvider.mistral) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: MemoriaTokens.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: MemoriaTokens.labelSm(color: MemoriaTokens.primaryDark),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            provider.description,
                            style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Key indicator badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasKey
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: hasKey
                                        ? const Color(0xFF81C784)
                                        : const Color(0xFFFFB74D),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  hasKey ? 'Key Set' : 'No Key',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: hasKey
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  isEditing ? LucideIcons.chevronUp : LucideIcons.keyRound,
                                  size: 18,
                                  color: isEditing
                                      ? MemoriaTokens.primary
                                      : MemoriaTokens.outline,
                                ),
                                onPressed: () {
                                  if (isEditing) {
                                    setState(() => _editingProvider = null);
                                  } else {
                                    _startEditingKey(provider, rawKey);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        // Expandable API Key input section
                        if (isEditing) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1, color: MemoriaTokens.polaroidBorder),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Enter your ${provider.displayName} API Key:',
                                      style: MemoriaTokens.labelSm(),
                                    ),
                                    InkWell(
                                      onTap: () => _openConsole(provider.consoleUrl),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Get API Key',
                                            style: MemoriaTokens.labelSm(
                                              color: MemoriaTokens.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            LucideIcons.externalLink,
                                            size: 12,
                                            color: MemoriaTokens.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _keyController,
                                        obscureText: _obscureText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'sk-...',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          filled: true,
                                          fillColor: MemoriaTokens.surfaceBright,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: const BorderSide(
                                              color: MemoriaTokens.polaroidBorder,
                                            ),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureText
                                                  ? LucideIcons.eye
                                                  : LucideIcons.eyeOff,
                                              size: 16,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureText = !_obscureText;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _saveKey(provider),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MemoriaTokens.primary,
                                        foregroundColor: MemoriaTokens.onPrimary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVlmManagementSection(LocalVlmModelManager vlmManager) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MemoriaTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
        border: Border.all(color: MemoriaTokens.polaroidBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: MemoriaTokens.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.cpu,
                  size: 20,
                  color: MemoriaTokens.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edge AI Engine Architecture',
                      style: MemoriaTokens.labelMd(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dual-Tier On-Device Vision Intelligence',
                      style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: MemoriaTokens.polaroidBorder),
          const SizedBox(height: 14),

          // Tier 1: Fast Computer Vision
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MemoriaTokens.surfaceContainerLow,
              borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
              border: Border.all(
                color: MemoriaTokens.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.zap, size: 18, color: MemoriaTokens.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tier 1: Instant Vision',
                            style: MemoriaTokens.labelSm(color: MemoriaTokens.onSurface),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MemoriaTokens.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Active • <50ms',
                              style: MemoriaTokens.labelSm(color: MemoriaTokens.secondary)
                                  .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Offline neural classification with expanded 500+ object lexicon (trash cans, furniture, kitchenware, tools) with zero waiting.',
                        style: MemoriaTokens.bodySm(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tier 2: PaliGemma 3B Multimodal VLM
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: vlmManager.hasModel
                  ? MemoriaTokens.primaryContainer.withValues(alpha: 0.3)
                  : MemoriaTokens.surfaceContainerLow,
              borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
              border: Border.all(
                color: vlmManager.hasModel
                    ? MemoriaTokens.primary
                    : MemoriaTokens.polaroidBorder,
                width: vlmManager.hasModel ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.sparkles, size: 18, color: MemoriaTokens.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tier 2: Gemma / PaliGemma 3B',
                              style: MemoriaTokens.labelSm(color: MemoriaTokens.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: vlmManager.hasModel
                            ? MemoriaTokens.primaryContainer
                            : (vlmManager.isDownloading
                                ? MemoriaTokens.tertiaryContainer
                                : MemoriaTokens.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        vlmManager.hasModel
                            ? 'Ready • ${vlmManager.formattedModelSize}'
                            : (vlmManager.isDownloading
                                ? 'Downloading ${vlmManager.currentStatus.formattedProgress}'
                                : 'Optional (~1.8 GB)'),
                        style: MemoriaTokens.labelSm(
                          color: vlmManager.hasModel
                              ? MemoriaTokens.primary
                              : (vlmManager.isDownloading
                                  ? MemoriaTokens.tertiary
                                  : MemoriaTokens.onSurfaceVariant),
                        ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  vlmManager.hasModel
                      ? 'PaliGemma weights loaded. Deep on-device visual language understanding is ready.'
                      : 'Google\'s 3B Vision-Language Model. Enables full contextual scene reasoning locally like cloud models.',
                  style: MemoriaTokens.bodySm(),
                ),

                if (vlmManager.isDownloading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: vlmManager.progress > 0 ? vlmManager.progress : null,
                    backgroundColor: MemoriaTokens.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(MemoriaTokens.primary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vlmManager.currentStatus.formattedDownloadedMb,
                        style: MemoriaTokens.bodySm(color: MemoriaTokens.onSurfaceVariant),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          vlmManager.cancelDownload();
                        },
                        icon: const Icon(LucideIcons.x, size: 14, color: Colors.red),
                        label: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 12)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                ],

                if (vlmManager.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vlmManager.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                if (vlmManager.hasModel) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete PaliGemma Model?'),
                          content: const Text(
                            'This will free up ~1.8 GB of device storage. You will automatically fall back to Tier 1 fast on-device vision.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await vlmManager.deleteModel();
                      }
                    },
                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                    label: const Text('Delete Model Weights', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ] else if (!vlmManager.isDownloading) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            vlmManager.startDownload();
                          },
                          icon: const Icon(LucideIcons.download, size: 16),
                          label: const Text('Download VLM (~1.8 GB)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MemoriaTokens.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Import Local Model (.bin/.task)',
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          final success = await vlmManager.importModelFromFilePicker();
                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PaliGemma model imported successfully!')),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.folderInput, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: MemoriaTokens.surfaceContainerHigh,
                        ),
                      ),
                    ],
                  ),

                  // Collapsible Advanced Settings (Custom URL & HF Token)
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showCustomUrl = !_showCustomUrl;
                      });
                      if (!_hfTokenLoaded) {
                        _hfTokenLoaded = true;
                        vlmManager.getHfToken().then((token) {
                          if (mounted && token.isNotEmpty) {
                            _hfTokenController.text = token;
                          }
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _showCustomUrl ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                            size: 14,
                            color: MemoriaTokens.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Advanced Download Options (HF Token / URL)',
                            style: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showCustomUrl) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Hugging Face Access Token (Free for gated models):',
                      style: MemoriaTokens.labelSm(),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _hfTokenController,
                      style: MemoriaTokens.bodySm(),
                      decoration: InputDecoration(
                        hintText: 'hf_xxxxxxxxxxxxxxxxxxxxxxxx',
                        hintStyle: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.check, size: 16),
                          tooltip: 'Save HF Token',
                          onPressed: () async {
                            await vlmManager.setHfToken(_hfTokenController.text.trim());
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Hugging Face Token saved')),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Custom Download URL:',
                      style: MemoriaTokens.labelSm(),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _customUrlController,
                      style: MemoriaTokens.bodySm(),
                      decoration: InputDecoration(
                        hintText: LocalVlmModelManager.defaultModelUrl,
                        hintStyle: MemoriaTokens.bodySm(color: MemoriaTokens.outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.check, size: 16),
                          tooltip: 'Save Download URL',
                          onPressed: () async {
                            await vlmManager.setCustomDownloadUrl(_customUrlController.text);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Download URL updated')),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
