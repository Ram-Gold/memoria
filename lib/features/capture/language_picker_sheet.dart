import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';
import '../../core/theme/memoria_tokens.dart';

class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLanguage = ref.watch(activeLanguageProvider);

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
              Text(
                'Target Language',
                style: MemoriaTokens.headlineMd(),
              ),
              const SizedBox(height: 4),
              Text(
                'Select the language you want your real-world camera exposures to teach you.',
                style: MemoriaTokens.bodySm(),
              ),
              const SizedBox(height: 16),
              Text(
                'TIER 1 (FULL PEDAGOGICAL PACKS):',
                style: MemoriaTokens.labelSm(color: MemoriaTokens.primaryDark),
              ),
              const SizedBox(height: 8),
              ...LanguageRegistry.focusLanguages.map((lang) {
                final isSelected = lang.code == activeLanguage.code;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? MemoriaTokens.primaryContainer : MemoriaTokens.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                    border: Border.all(
                      color: isSelected ? MemoriaTokens.primary : MemoriaTokens.polaroidBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Text(lang.flagEmoji, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      '${lang.displayName} (${lang.englishName})',
                      style: MemoriaTokens.labelLg(
                        color: isSelected ? MemoriaTokens.primaryDark : MemoriaTokens.onSurface,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: MemoriaTokens.primary) : null,
                    onTap: () {
                      ref.read(activeLanguageProvider.notifier).state = lang;
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }),
              const SizedBox(height: 14),
              Text(
                'TIER 2 (GLOBAL PRESETS):',
                style: MemoriaTokens.labelSm(color: MemoriaTokens.secondary),
              ),
              const SizedBox(height: 8),
              ...LanguageRegistry.presets.where((l) => !l.isFocusLanguage).map((lang) {
                final isSelected = lang.code == activeLanguage.code;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? MemoriaTokens.secondaryContainer : MemoriaTokens.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
                    border: Border.all(
                      color: isSelected ? MemoriaTokens.secondary : MemoriaTokens.polaroidBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Text(lang.flagEmoji, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      '${lang.displayName} (${lang.englishName})',
                      style: MemoriaTokens.labelLg(
                        color: isSelected ? MemoriaTokens.secondary : MemoriaTokens.onSurface,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: MemoriaTokens.secondary) : null,
                    onTap: () {
                      ref.read(activeLanguageProvider.notifier).state = lang;
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
