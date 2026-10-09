import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../theme/memoria_tokens.dart';
import 'rubber_stamp.dart';
import 'washi_tape.dart';

/// Reusable Tactile Polaroid Card with authentic film ratios (1:1, 3:4, 4:3),
/// generous chin margin, handwritten script typography, and optional washi tape/stamp.
class PolaroidFrame extends StatelessWidget {
  final Widget? imageWidget;
  final String? imagePath;
  final PolaroidFormat format;
  final String? primaryText;
  final String? subtitleText;
  final String? filmMetaText;
  final bool showWashiTape;
  final bool isStamped;
  final VoidCallback? onStampTap;
  final VoidCallback? onTap;
  final double angle;
  final double? width;
  final double chinHeight;
  final double cardPadding;
  final bool isElevated;
  final double? primaryFontSize;
  final double? subtitleFontSize;

  const PolaroidFrame({
    super.key,
    this.imageWidget,
    this.imagePath,
    this.format = PolaroidFormat.square,
    this.primaryText,
    this.subtitleText,
    this.filmMetaText,
    this.showWashiTape = false,
    this.isStamped = false,
    this.onStampTap,
    this.onTap,
    this.angle = 0.0,
    this.width,
    this.chinHeight = 56.0,
    this.cardPadding = 10.0,
    this.isElevated = true,
    this.primaryFontSize,
    this.subtitleFontSize,
  });

  @override
  Widget build(BuildContext context) {
    Widget photoContent;
    if (imageWidget != null) {
      photoContent = imageWidget!;
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        photoContent = Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        photoContent = Container(
          color: MemoriaTokens.surfaceContainerHigh,
          child: const Center(
            child: Icon(LucideIcons.imageOff, color: MemoriaTokens.outline),
          ),
        );
      }
    } else {
      photoContent = Container(
        color: MemoriaTokens.emulsionDark,
      );
    }

    Widget cardBody = Container(
      width: width,
      decoration: BoxDecoration(
        color: MemoriaTokens.polaroidCard,
        borderRadius: BorderRadius.circular(MemoriaTokens.radiusSm),
        border: Border.all(color: MemoriaTokens.polaroidBorder, width: 1),
        boxShadow: isElevated ? MemoriaTokens.shadowPolaroid : MemoriaTokens.shadowLevel1,
      ),
      padding: EdgeInsets.fromLTRB(cardPadding, cardPadding, cardPadding, cardPadding * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photographic Aperture Window
          AspectRatio(
            aspectRatio: format.ratio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 0.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: photoContent,
            ),
          ),

          // The Signature Polaroid Chin Margin
          if (chinHeight > 0 ||
              (primaryText != null && primaryText!.isNotEmpty) ||
              (subtitleText != null && subtitleText!.isNotEmpty) ||
              isStamped ||
              onStampTap != null)
            Container(
              constraints: BoxConstraints(minHeight: chinHeight),
              padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: (isStamped || onStampTap != null) ? 28.0 : 0.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (primaryText != null && primaryText!.isNotEmpty) ...[
                          Text(
                            primaryText!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MemoriaTokens.handwrittenChin(
                              fontSize: primaryFontSize ?? (chinHeight > 60 ? 28 : (chinHeight < 45 ? 15 : 20)),
                              color: MemoriaTokens.onSurface,
                            ),
                          ),
                        ],
                        if (subtitleText != null && subtitleText!.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            subtitleText!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MemoriaTokens.bodySm(
                              color: MemoriaTokens.onSurfaceVariant,
                            ).copyWith(
                              fontSize: subtitleFontSize ?? (chinHeight < 45 ? 9.5 : null),
                            ),
                          ),
                        ],
                        if (filmMetaText != null && filmMetaText!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            filmMetaText!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MemoriaTokens.telemetryMono(
                              fontSize: 8.5,
                              color: MemoriaTokens.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Rubber Heart Stamp on Chin
                  if (isStamped || onStampTap != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: RubberStampWidget(
                        isStamped: isStamped,
                        onTap: onStampTap,
                        size: chinHeight > 60 ? 32 : 24,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    Widget result = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        cardBody,
        if (showWashiTape)
          const Positioned(
            top: -10,
            child: WashiTapeWidget(),
          ),
      ],
    );

    if (angle != 0.0) {
      result = Transform.rotate(angle: angle, child: result);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: result,
      );
    }

    return result;
  }
}
