import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:world_flags/world_flags.dart';
import '../languages/language_profile.dart';
import '../theme/memoria_tokens.dart';

/// Reusable analog-styled vector flag icon using [world_flags]
class LanguageFlagIcon extends StatelessWidget {
  final LanguageProfile language;
  final double width;
  final double? height;
  final double borderRadius;
  final bool showBorder;

  const LanguageFlagIcon({
    super.key,
    required this.language,
    this.width = 24,
    this.height,
    this.borderRadius = 3.0,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final country = language.country;
    final h = height ?? (width * 0.68);

    if (country != null) {
      return Container(
        width: width,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: showBorder
              ? Border.all(
                  color: Colors.black.withValues(alpha: 0.15),
                  width: 0.8,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 1.5,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
        child: CountryFlag.simplified(
          country,
          aspectRatio: 3 / 2,
        ),
      );
    }

    // Elegant fallback icon for custom languages without a mapped country
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: MemoriaTokens.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: Colors.black.withValues(alpha: 0.12),
                width: 0.8,
              )
            : null,
      ),
      child: Center(
        child: Icon(
          LucideIcons.globe,
          size: h * 0.75,
          color: MemoriaTokens.outline,
        ),
      ),
    );
  }
}
