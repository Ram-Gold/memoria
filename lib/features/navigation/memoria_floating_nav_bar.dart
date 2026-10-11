import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/memoria_tokens.dart';

class NavItemData {
  final IconData icon;
  final String label;

  const NavItemData({
    required this.icon,
    required this.label,
  });
}

/// Tactile Editorial Analog Floating Navigation Bar.
///
/// Features:
/// - Camera-body matte obsidian capsule background with subtle rim border
/// - Butter-smooth animated expanding active pill with terracotta accent
/// - Responsive scaling for compact mobile devices (<360px & <400px)
/// - Haptic feedback on selection without external navigation bar dependencies
class MemoriaFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<NavItemData> items;

  const MemoriaFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.items = const [
      NavItemData(icon: LucideIcons.camera, label: 'Camera'),
      NavItemData(icon: LucideIcons.calendarDays, label: 'Calendar'),
      NavItemData(icon: LucideIcons.images, label: 'Scrapbook'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isNarrow = screenWidth < 400;

    // Responsive design tokens
    final capsulePaddingH = isCompact ? 6.0 : (isNarrow ? 8.0 : 10.0);
    final capsulePaddingV = isCompact ? 5.0 : (isNarrow ? 6.0 : 7.0);
    final tabGap = isCompact ? 4.0 : (isNarrow ? 6.0 : 8.0);

    return Container(
      decoration: BoxDecoration(
        color: MemoriaTokens.cameraObsidian, // Deep camera-body matte obsidian
        borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
        boxShadow: MemoriaTokens.shadowCapsule,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: capsulePaddingH,
        vertical: capsulePaddingV,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: tabGap),
            _buildTabItem(context, i, isCompact, isNarrow),
          ],
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    int index,
    bool isCompact,
    bool isNarrow,
  ) {
    final isSelected = index == selectedIndex;
    final item = items[index];

    final iconSize = isCompact ? 17.0 : (isNarrow ? 19.0 : 21.0);
    final fontSize = isCompact ? 11.5 : (isNarrow ? 12.5 : 13.5);
    final horizontalPad = isSelected
        ? (isCompact ? 10.0 : (isNarrow ? 12.0 : 14.0))
        : (isCompact ? 8.0 : (isNarrow ? 10.0 : 12.0));
    final verticalPad = isCompact ? 6.0 : (isNarrow ? 7.0 : 8.0);
    final labelGap = isCompact ? 4.0 : 6.0;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (index != selectedIndex) {
              HapticFeedback.selectionClick();
              onTabSelected(index);
            }
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected ? MemoriaTokens.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPad,
              vertical: verticalPad,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: iconSize,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: isSelected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: labelGap),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
