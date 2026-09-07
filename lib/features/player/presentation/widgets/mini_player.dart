import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    if (!playerState.hasTrack) return const SizedBox.shrink();

    final item = playerState.current!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PlayerScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                SlideTransition(position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim), child: child),
          ),
        );
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: LumaColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item.thumbnailUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(color: LumaColors.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.author,
                            style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        playerState.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: playerState.isFavorite ? LumaColors.accent : LumaColors.darkTextPrimary,
                        size: 22,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).toggleFavorite(),
                    ),
                    IconButton(
                      icon: playerState.isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(
                              playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: LumaColors.darkTextPrimary,
                              size: 28,
                            ),
                      onPressed: () => ref.read(playerProvider.notifier).togglePlayPause(),
                    ),
                  ],
                ),
              ),
            ),
            // Progress Bar
            if (playerState.duration.inMilliseconds > 0)
              LinearProgressIndicator(
                value: playerState.position.inMilliseconds / playerState.duration.inMilliseconds,
                backgroundColor: LumaColors.darkDivider,
                valueColor: const AlwaysStoppedAnimation<Color>(LumaColors.accent),
                minHeight: 2,
              )
            else
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
