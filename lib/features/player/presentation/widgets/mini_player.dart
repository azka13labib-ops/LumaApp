import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PlayerScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: LumaColors.darkSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // Artwork — consistent with list tile size
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
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
                      const SizedBox(width: 12),
                      // Title + artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: LumaColors.darkTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      // Like — 44×44 touch target
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
                          onPressed: () =>
                              ref.read(playerProvider.notifier).toggleFavorite(),
                        ),
                      ),
                      // Play/Pause — 44×44 touch target
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
                          onPressed: () =>
                              ref.read(playerProvider.notifier).togglePlayPause(),
                        ),
                      ),
                      // Next
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.skip_next_rounded,
                              color: Colors.white70, size: 24),
                          onPressed: () =>
                              ref.read(playerProvider.notifier).next(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Progress bar — 2px at very bottom
              if (ps.duration.inMilliseconds > 0)
                LinearProgressIndicator(
                  value: ps.position.inMilliseconds /
                      ps.duration.inMilliseconds,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white54),
                  minHeight: 2,
                )
              else
                const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}
