import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/widgets/luma_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../player/presentation/widgets/play_shuffle_bar.dart';
import '../../../player/presentation/widgets/track_row.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});
  final Map<String, dynamic> playlist;

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  final _supabase = Supabase.instance.client;
  List<MusicItem> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('playlist_items')
          .select()
          .eq('playlist_id', widget.playlist['id'])
          .order('added_at');

      _songs = (res as List)
          .map((e) => MusicItem.fromMap(
                Map<String, dynamic>.from(e as Map),
                missingTitle: 'Unknown',
                missingArtist: 'Unknown Artist',
              ))
          .toList();
    } catch (e) {
      debugPrint('Playlist detail error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumaColors.darkSurface,
        title: const Text('Hapus Playlist?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Playlist "${widget.playlist['name']}" akan dihapus permanen.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _supabase
          .from('playlists')
          .delete()
          .eq('id', widget.playlist['id']);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.playlist['name'] ?? 'Playlist';

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: LumaColors.darkBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54),
                onPressed: _deletePlaylist,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      LumaColors.accent.withValues(alpha: 0.5),
                      LumaColors.darkBg,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: LumaColors.darkSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.queue_music_rounded,
                          color: Colors.white38, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Playlist • Kamu',
                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

          // ── Play Controls ──
          if (!_loading && _songs.isNotEmpty)
            SliverToBoxAdapter(
              child: PlayShuffleBar(
                onPlayAll: () => ref.read(playerProvider.notifier).play(_songs, 0),
                onShuffle: () {
                  final shuffled = List<MusicItem>.from(_songs)..shuffle();
                  ref.read(playerProvider.notifier).play(shuffled, 0);
                },
              ),
            ),

          // ── Song Count ──
          if (!_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('${_songs.length} lagu',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),

          // ── Track List ──
          if (_loading)
            const SliverFillRemaining(
              child: LumaListSkeleton(count: 7),
            )
          else if (_songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.playlist_add_rounded,
                        color: Colors.white12, size: 56),
                    SizedBox(height: 16),
                    Text('Playlist masih kosong',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14)),
                    SizedBox(height: 8),
                    Text('Tambahkan lagu dari hasil pencarian',
                        style:
                            TextStyle(color: Colors.white30, fontSize: 12)),
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
                    final item = _songs[i];
                    return TrackRow(
                      item: item,
                      onTap: () =>
                          ref.read(playerProvider.notifier).play(_songs, i),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            color: Colors.white24, size: 20),
                        onPressed: () async {
                          await _supabase
                              .from('playlist_items')
                              .delete()
                              .eq('playlist_id', widget.playlist['id'])
                              .eq('youtube_id', item.id);
                          _fetchSongs();
                        },
                      ),
                    );
                  },
                  childCount: _songs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
