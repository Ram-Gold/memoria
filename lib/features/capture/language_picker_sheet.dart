import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/languages/language_profile.dart';

class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLanguage = ref.watch(activeLanguageProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Target Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Focus Languages (Tier 1):', style: TextStyle(fontWeight: FontWeight.w600)),
            ...LanguageRegistry.focusLanguages.map((lang) {
              final isSelected = lang.code == activeLanguage.code;
              return ListTile(
                leading: Text(lang.flagEmoji, style: const TextStyle(fontSize: 24)),
                title: Text('${lang.displayName} (${lang.englishName})'),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  ref.read(activeLanguageProvider.notifier).state = lang;
                  Navigator.of(context).pop();
                },
              );
            }),
            const Divider(),
            const Text('Popular Languages (Tier 2):', style: TextStyle(fontWeight: FontWeight.w600)),
            ...LanguageRegistry.presets.where((l) => !l.isFocusLanguage).map((lang) {
              final isSelected = lang.code == activeLanguage.code;
              return ListTile(
                leading: Text(lang.flagEmoji, style: const TextStyle(fontSize: 24)),
                title: Text('${lang.displayName} (${lang.englishName})'),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  ref.read(activeLanguageProvider.notifier).state = lang;
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
