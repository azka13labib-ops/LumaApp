import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _supabase = Supabase.instance.client;
  List<MusicItem> _likedSongs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikedSongs();
  }

  Future<void> _fetchLikedSongs() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await _supabase
          .from('liked_songs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final items = (res as List).map((e) => MusicItem(
        id: e['youtube_id'],
        title: e['title'],
        author: e['author'],
        thumbnailUrl: e['thumbnail'],
      )).toList();

      if (mounted) {
        setState(() {
          _likedSongs = items;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Library error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: LumaColors.darkSurface,
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            const Text('Koleksi Kamu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: LumaColors.accent))
          : RefreshIndicator(
              onRefresh: _fetchLikedSongs,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  const SizedBox(height: 16),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildChip('Playlist', true),
                        const SizedBox(width: 8),
                        _buildChip('Album', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Liked Songs Pinned Item
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                    ),
                    title: const Text('Lagu yang Disukai', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    subtitle: Text('${_likedSongs.length} lagu', style: const TextStyle(color: LumaColors.darkTextSecondary)),
                    onTap: () {
                      if (_likedSongs.isNotEmpty) {
                        ref.read(playerProvider.notifier).play(_likedSongs, 0);
                      }
                    },
                  ),
                  
                  // Playlists (dummy for now)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 64,
                      height: 64,
                      color: LumaColors.darkSurface,
                      child: const Icon(Icons.music_note, color: Colors.white54, size: 32),
                    ),
                    title: const Text('Playlist Saya #1', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Playlist • Kamu', style: TextStyle(color: LumaColors.darkTextSecondary)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? LumaColors.accent : LumaColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : LumaColors.darkTextPrimary,
          fontSize: 13,
        ),
      ),
    );
  }
}
