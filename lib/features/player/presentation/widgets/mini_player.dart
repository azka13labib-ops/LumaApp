import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ps = ref.watch(playerProvider);
    if (!ps.hasTrack) return const SizedBox.shrink();

    final item = ps.current!;

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
            color: LumaColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 8),
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
                          child: Image.network(
                            item.thumbnailUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFF222222),
                              child: const Icon(Icons.music_note_rounded,
                                  color: Colors.white24, size: 20),
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
                                    style: const TextStyle(
                                      color: LumaColors.darkTextPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (ps.isCached)
                                  const Icon(Icons.download_done_rounded,
                                      color: LumaColors.accent, size: 14),
                              ],
                            ),
                            Text(
                              item.author,
                              style: const TextStyle(
                                color: LumaColors.darkTextSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Like: 44x44 touch target with haptic feedback
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            ps.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: ps.isFavorite
                                ? LumaColors.accent
                                : LumaColors.darkTextPrimary,
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(playerProvider.notifier).toggleFavorite();
                          },
                        ),
                      ),
                      // Play/Pause: 44x44 touch target with haptic feedback
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: ps.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white54))
                              : Icon(
                                  ps.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: LumaColors.darkTextPrimary,
                                  size: 28,
                                ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(playerProvider.notifier).togglePlayPause();
                          },
                        ),
                      ),
                      // Next with haptic feedback
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.skip_next_rounded,
                              color: Colors.white70, size: 24),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(playerProvider.notifier).next();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Progress bar: visible accent color at bottom
              if (ps.duration.inMilliseconds > 0)
                LinearProgressIndicator(
                  value: (ps.position.inMilliseconds /
                          ps.duration.inMilliseconds)
                      .clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(LumaColors.accent),
                  minHeight: 2.5,
                )
              else
                const SizedBox(height: 2.5),
            ],
          ),
        ),
      ),
    );
  }
}
