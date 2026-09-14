import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../player/presentation/widgets/play_shuffle_bar.dart';
import '../../../player/presentation/widgets/track_row.dart';
import '../../../player/presentation/widgets/mini_player.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key, required this.songs});
  final List<MusicItem> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark ? LumaColors.darkTextSecondary : LumaColors.lightTextSecondary;
    final hasTrack = ref.watch(playerProvider.select((s) => s.hasTrack));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: hasTrack
          ? const SafeArea(
              top: false,
              child: MiniPlayer(),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF18181B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF18181B),
                      Color(0xFF27272A),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 72),
                    const SizedBox(height: 12),
                    const Text('Lagu yang Disukai',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${songs.length} lagu',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),

          // ── Play Controls ──
          if (songs.isNotEmpty)
            SliverToBoxAdapter(
              child: PlayShuffleBar(
                onPlayAll: () => ref.read(playerProvider.notifier).play(songs, 0),
                onShuffle: () {
                  final shuffled = List<MusicItem>.from(songs)..shuffle();
                  ref.read(playerProvider.notifier).play(shuffled, 0);
                },
              ),
            ),

          // ── Track List ──
          if (songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        color: isDark ? Colors.white12 : Colors.black12, size: 56),
                    const SizedBox(height: 16),
                    Text('Belum ada lagu yang disukai',
                        style: TextStyle(color: textSecondary, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('Sukai lagu dari hasil pencarian',
                        style: TextStyle(
                            color: isDark ? Colors.white30 : LumaColors.lightTextMuted,
                            fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(bottom: hasTrack ? 24 : 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = songs[i];
                    return TrackRow(
                      item: item,
                      onTap: () => ref.read(playerProvider.notifier).play(songs, i),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
