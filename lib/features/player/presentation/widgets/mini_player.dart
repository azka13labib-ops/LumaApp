import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_heart_button.dart';
import '../../../../core/widgets/interactive_scale_button.dart';
import '../screens/player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hanya watch state yang relevan, JANGAN watch posisi di sini
    final state = ref.watch(playerProvider.select((s) => (
      hasTrack: s.current != null,
      current: s.current,
      isFavorite: s.isFavorite,
      isPlaying: s.isPlaying,
      isLoading: s.isLoading,
      isCached: s.isCached,
    )));

    if (!state.hasTrack) return const SizedBox.shrink();

    final item = state.current!;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? LumaColors.darkSurfaceElevated : Colors.white;
    final cardBorder = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1)
        : Border.all(color: LumaColors.lightBorder, width: 1);
    final textPrimary = isDark ? LumaColors.darkTextPrimary : LumaColors.lightTextPrimary;
    final textSecondary = isDark ? LumaColors.darkTextSecondary : LumaColors.lightTextSecondary;
    final accentColor = isDark ? Colors.white : const Color(0xFF18181B);
    final inactiveIconColor = isDark ? Colors.white70 : LumaColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GestureDetector(
          onHorizontalDragEnd: (details) {
            final vx = details.primaryVelocity ?? 0;
            if (vx < -250) {
              HapticFeedback.lightImpact();
              ref.read(playerProvider.notifier).next();
            } else if (vx > 250) {
              HapticFeedback.lightImpact();
              ref.read(playerProvider.notifier).previous();
            }
          },
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const PlayerScreen(),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutQuart)),
                child: child,
              ),
            ),
          ),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: cardBorder,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Artwork with Hero animation
                        Hero(
                          tag: 'player_artwork_${item.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: item.thumbnailUrl,
                              width: 44,
                              height: 44,
                              memCacheWidth: 88, // 2x retina
                              memCacheHeight: 88,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 44,
                                height: 44,
                                color: isDark ? const Color(0xFF222222) : LumaColors.lightSurface,
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 44,
                                height: 44,
                                color: isDark ? const Color(0xFF222222) : LumaColors.lightSurface,
                                child: Icon(Icons.music_note_rounded,
                                    color: isDark ? Colors.white24 : LumaColors.lightTextMuted, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title + artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (state.isCached)
                                    Icon(Icons.download_done_rounded,
                                        color: accentColor, size: 14),
                                ],
                              ),
                              Text(
                                item.author,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Like: bouncy animated heart
                        AnimatedHeartButton(
                          isLiked: state.isFavorite,
                          size: 20,
                          activeColor: const Color(0xFFEF4444),
                          inactiveColor: inactiveIconColor,
                          onTap: () => ref.read(playerProvider.notifier).toggleFavorite(),
                        ),
                        // Play/Pause: bouncy spring press
                        InteractiveScaleButton(
                          pressedScale: 0.85,
                          onTap: () => ref.read(playerProvider.notifier).togglePlayPause(),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: state.isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: isDark ? Colors.white54 : LumaColors.lightTextSecondary))
                                  : Icon(
                                      state.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: textPrimary,
                                      size: 28,
                                    ),
                            ),
                          ),
                        ),
                        // Next with bouncy spring press
                        InteractiveScaleButton(
                          pressedScale: 0.88,
                          onTap: () => ref.read(playerProvider.notifier).next(),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Icon(Icons.skip_next_rounded,
                                  color: inactiveIconColor, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Progress bar terpisah
                _MiniPlayerProgressBar(isDark: isDark, accentColor: accentColor),
              ],
            ),
          ),
        ),
      );
  }
}

class _MiniPlayerProgressBar extends ConsumerWidget {
  const _MiniPlayerProgressBar({required this.isDark, required this.accentColor});
  final bool isDark;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref.watch(playerProvider.select((s) => s.duration));
    final position = ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;

    if (duration.inMilliseconds > 0) {
      return LinearProgressIndicator(
        value: (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0),
        backgroundColor: isDark ? Colors.white12 : LumaColors.lightDivider,
        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
        minHeight: 2.5,
      );
    } else {
      return const SizedBox(height: 2.5);
    }
  }
}
