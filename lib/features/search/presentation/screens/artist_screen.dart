import 'package:flutter/material.dart';
import '../../../../core/widgets/luma_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../player/presentation/widgets/mini_player.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white : LumaColors.lightTextPrimary);
    final textSecondary = theme.textTheme.labelSmall?.color ?? (isDark ? LumaColors.darkTextSecondary : LumaColors.lightTextSecondary);
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
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.artistName,
                style: TextStyle(
                  color: textPrimary,
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
                      isDark
                          ? const Color(0xFF27272A).withValues(alpha: 0.35)
                          : const Color(0xFFE4E4E7).withValues(alpha: 0.5),
                      theme.scaffoldBackgroundColor,
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
                    Text(_error!, style: TextStyle(color: textSecondary)),
                    TextButton(
                      onPressed: _load,
                      child: Text('Coba lagi', style: TextStyle(color: theme.colorScheme.primary)),
                    ),
                  ],
                ),
              ),
            )
          else if (_tracks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Tidak ada lagu ditemukan.',
                  style: TextStyle(color: textSecondary),
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
                        foregroundColor: textPrimary,
                        side: BorderSide(color: theme.dividerColor),
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
              padding: EdgeInsets.only(bottom: hasTrack ? 24 : 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = _tracks[i];
                    return ListTile(
                      onTap: () => ref.read(playerProvider.notifier).play(_tracks, i),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: item.thumbnailUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 48,
                            height: 48,
                            color: isDark ? LumaColors.darkSurface : LumaColors.lightSurface,
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 48,
                            height: 48,
                            color: isDark ? LumaColors.darkSurface : LumaColors.lightSurface,
                            child: Icon(Icons.music_note,
                                color: isDark ? Colors.white38 : LumaColors.lightTextMuted),
                          ),
                        ),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        item.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.playlist_add_rounded,
                            color: isDark ? Colors.white38 : LumaColors.lightTextMuted),
                        onPressed: () {
                          ref.read(playerProvider.notifier).addToQueue(item);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Ditambahkan ke antrian'),
                            backgroundColor: isDark ? LumaColors.darkSurface : const Color(0xFF18181B),
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
