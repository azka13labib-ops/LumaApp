import 'package:flutter/material.dart';
import '../../../../core/widgets/luma_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';

class ArtistScreen extends ConsumerStatefulWidget {
  const ArtistScreen({super.key, required this.artistName});

  final String artistName;

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  final YouTubeService _yt = YouTubeService();
  List<MusicItem> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _yt.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _yt.searchMusic(widget.artistName);
      final name = widget.artistName.toLowerCase();
      final preferred = results
          .where((t) =>
              t.author.toLowerCase().contains(name) ||
              name.contains(t.author.toLowerCase()))
          .toList();
      if (mounted) {
        setState(() {
          _tracks = preferred.isNotEmpty ? preferred : results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat lagu artis.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: LumaColors.darkBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.artistName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      LumaColors.accent.withValues(alpha: 0.35),
                      LumaColors.darkBg,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: LumaListSkeleton(count: 8, showTrailing: true),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Coba lagi', style: TextStyle(color: LumaColors.accent)),
                    ),
                  ],
                ),
              ),
            )
          else if (_tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Tidak ada lagu ditemukan.',
                  style: TextStyle(color: LumaColors.darkTextSecondary),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => ref.read(playerProvider.notifier).play(_tracks, 0),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text('Putar'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      onPressed: () {
                        final shuffled = List<MusicItem>.from(_tracks)..shuffle();
                        ref.read(playerProvider.notifier).play(shuffled, 0);
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text('Acak'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = _tracks[i];
                    return ListTile(
                      onTap: () => ref.read(playerProvider.notifier).play(_tracks, i),
                      leading: ClipRRect(
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
                            child: const Icon(Icons.music_note, color: Colors.white38),
                          ),
                        ),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        item.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.playlist_add_rounded, color: Colors.white38),
                        onPressed: () {
                          ref.read(playerProvider.notifier).addToQueue(item);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Ditambahkan ke antrian'),
                            backgroundColor: LumaColors.darkSurface,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ));
                        },
                      ),
                    );
                  },
                  childCount: _tracks.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
