import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'interactive_scale_button.dart';

class LumaNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const LumaNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

class LumaAnimatedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LumaNavItem> items;

  const LumaAnimatedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = const [
      LumaNavItem(
        label: 'Beranda',
        activeIcon: Icons.home_filled,
        inactiveIcon: Icons.home_outlined,
      ),
      LumaNavItem(
        label: 'Cari',
        activeIcon: Icons.search_rounded,
        inactiveIcon: Icons.search,
      ),
      LumaNavItem(
        label: 'Koleksi',
        activeIcon: Icons.library_music_rounded,
        inactiveIcon: Icons.library_music_outlined,
      ),
      LumaNavItem(
        label: 'Premium',
        activeIcon: Icons.workspace_premium_rounded,
        inactiveIcon: Icons.workspace_premium_outlined,
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF18181B);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.4),
            width: 0.6,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final itemWidth = totalWidth / items.length;
          const boxPadding = 4.0;
          final activeBoxWidth = itemWidth - (boxPadding * 2);
          const activeBoxHeight = 52.0;

          return SizedBox(
            height: 60,
            child: Stack(
              children: [
                // ── Animated Sliding Rounded Box Indicator ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  left: (currentIndex * itemWidth) + boxPadding,
                  top: 4,
                  width: activeBoxWidth,
                  height: activeBoxHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Interactive Navigation Item Slots ──
                Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;

                    return Expanded(
                      child: InteractiveScaleButton(
                        pressedScale: 0.88,
                        enableHaptic: false, // handled custom below with mediumImpact
                        onTap: () {
                          if (currentIndex != index) {
                            HapticFeedback.mediumImpact();
                            onTap(index);
                          }
                        },
                        child: Container(
                          height: 60,
                          color: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isSelected ? item.activeIcon : item.inactiveIcon,
                                  size: 22,
                                  color: isSelected ? textPrimary : textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? textPrimary : textSecondary,
                                  letterSpacing: -0.2,
                                ),
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
