import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key, required this.songs});
  final List<MusicItem> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF450AF5),
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
                    colors: [Color(0xFF450AF5), Color(0xFF8DC9CF)],
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    // Play All
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: LumaColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Putar Semua',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        onPressed: () =>
                            ref.read(playerProvider.notifier).play(songs, 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shuffle
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text('Acak', style: TextStyle(fontSize: 14)),
                      onPressed: () {
                        final shuffled = List<MusicItem>.from(songs)..shuffle();
                        ref.read(playerProvider.notifier).play(shuffled, 0);
                      },
                    ),
                  ],
                ),
              ),
            ),

          // ── Track List ──
          if (songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded, color: Colors.white12, size: 56),
                    SizedBox(height: 16),
                    Text('Belum ada lagu yang disukai',
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                    SizedBox(height: 8),
                    Text('Sukai lagu dari hasil pencarian',
                        style: TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 160),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = songs[i];
                    return _TrackTile(
                      item: item,
                      index: i,
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

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.item, required this.index, required this.onTap});
  final MusicItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.thumbnailUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: LumaColors.darkSurface,
                    child: const Icon(Icons.music_note, color: Colors.white30, size: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.author,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}
