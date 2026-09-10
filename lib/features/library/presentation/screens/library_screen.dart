import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../playlist/presentation/screens/create_playlist_screen.dart';
import 'liked_songs_screen.dart';
import 'playlist_detail_screen.dart';
import 'settings_screen.dart';
import 'downloads_screen.dart';
import '../../../../core/services/offline_cache_service.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _supabase = Supabase.instance.client;

  List<MusicItem> _likedSongs = [];
  List<Map<String, dynamic>> _playlists = [];
  List<MusicItem> _downloads = [];
  bool _loading = true;
  String _filter = 'Semua'; // Semua / Playlist / Lagu Disukai / Unduhan
  final _searchController = TextEditingController();
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    await Future.wait([_fetchLikedSongs(), _fetchPlaylists(), _fetchDownloads()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchDownloads() async {
    try {
      _downloads = await OfflineCacheService.instance.listCached();
    } catch (e) {
      debugPrint('Downloads error: $e');
    }
  }

  Future<void> _fetchLikedSongs() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final res = await _supabase
          .from('liked_songs')
          .select()
          .eq('user_id', user.id)
          .order('liked_at', ascending: false);

      _likedSongs = (res as List)
          .map((e) => MusicItem.fromMap(
                Map<String, dynamic>.from(e as Map),
                missingTitle: 'Unknown',
                missingArtist: 'Unknown Artist',
              ))
          .toList();
    } catch (e) {
      debugPrint('Liked songs error: $e');
    }
  }

  Future<void> _fetchPlaylists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final res = await _supabase
          .from('playlists')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      _playlists = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('Playlists error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: LumaColors.accent.withValues(alpha: 0.3),
                      child: Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Koleksi Kamu',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22)),
                  ),
                  IconButton(
                    icon: Icon(
                      _searchActive ? Icons.close_rounded : Icons.search_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchActive = !_searchActive;
                        if (!_searchActive) _searchController.clear();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreatePlaylistScreen()));
                      _fetchAll();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white54, size: 22),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
            ),

            // ── Search Bar (visible when active) ──
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _searchActive
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari di koleksi kamu...',
                          hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Filter Chips ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Semua', 'Playlist', 'Lagu Disukai', 'Unduhan'].map((f) {
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? LumaColors.accent : LumaColors.darkSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  color: selected ? Colors.white : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Body ──
            Expanded(
              child: _loading
                  ? _LibrarySkeleton()
                  : RefreshIndicator(
                      onRefresh: _fetchAll,
                      color: LumaColors.accent,
                      backgroundColor: LumaColors.darkSurface,
                      child: _buildList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final q = _searchController.text.toLowerCase();

    final showLiked = (_filter == 'Semua' || _filter == 'Lagu Disukai');
    final showPlaylists = (_filter == 'Semua' || _filter == 'Playlist');
    final showDownloads = (_filter == 'Semua' || _filter == 'Unduhan');

    final filteredPlaylists = _playlists
        .where((p) => q.isEmpty || (p['name'] ?? '').toLowerCase().contains(q))
        .toList();

    final items = <Widget>[];

    // Pinned: Unduhan (offline)
    if (showDownloads &&
        (q.isEmpty || 'unduhan'.contains(q) || 'download'.contains(q) || 'offline'.contains(q))) {
      items.add(_DownloadsRow(
        count: _downloads.length,
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadsScreen()));
          _fetchAll(); // refresh count after delete
        },
      ));
    }

    // Pinned: Lagu Disukai
    if (showLiked &&
        (q.isEmpty || 'lagu disukai'.contains(q) || 'liked songs'.contains(q))) {
      items.add(_LikedSongsRow(
        count: _likedSongs.length,
        songs: _likedSongs,
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => LikedSongsScreen(songs: _likedSongs)));
          _fetchAll();
        },
      ));
    }

    // Playlists dari DB
    if (showPlaylists) {
      for (final p in filteredPlaylists) {
        items.add(_PlaylistRow(
          playlist: p,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlist: p))),
        ));
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music_rounded, color: Colors.white12, size: 56),
            const SizedBox(height: 16),
            Text(
              q.isNotEmpty ? 'Tidak ada hasil untuk "$q"' : 'Koleksi masih kosong',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            if (q.isEmpty) ...[
              const SizedBox(height: 8),
              const Text('Tambah playlist atau sukai lagu untuk mulai',
                  style: TextStyle(color: Colors.white30, fontSize: 12)),
            ]
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 160),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }
}

// ── Downloads Row ─────────────────────────────────────────────────────────────

class _DownloadsRow extends StatelessWidget {
  const _DownloadsRow({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.download_done_rounded, color: Colors.white70, size: 28),
      ),
      title: const Text('Unduhan',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(
        count == 0 ? 'Belum ada lagu tersimpan' : '$count lagu · tersimpan offline',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
      onTap: onTap,
    );
  }
}

// ── Liked Songs Row ──────────────────────────────────────────────────────────

class _LikedSongsRow extends StatelessWidget {
  const _LikedSongsRow({required this.count, required this.songs, required this.onTap});
  final int count;
  final List<MusicItem> songs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF450AF5), Color(0xFF8DC9CF)],
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
      ),
      title: const Text('Lagu yang Disukai',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text('$count lagu',
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
      onTap: onTap,
    );
  }
}

// ── Playlist Row ─────────────────────────────────────────────────────────────

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({required this.playlist, required this.onTap});
  final Map<String, dynamic> playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: LumaColors.darkSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.queue_music_rounded, color: Colors.white38, size: 26),
      ),
      title: Text(playlist['name'] ?? 'Playlist',
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: const Text('Playlist • Kamu',
          style: TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton for the library screen list
// ---------------------------------------------------------------------------
class _LibrarySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFF1E1E1E),
        highlightColor: Color(0xFF2E2E2E),
        duration: Duration(milliseconds: 1200),
      ),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (_, __) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Container(height: 13, width: 160, color: Colors.white),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(height: 11, width: 90, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
