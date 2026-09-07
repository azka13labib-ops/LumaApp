import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/player_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final YouTubeService _ytService = YouTubeService();
  final TextEditingController _controller = TextEditingController();
  List<MusicItem> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    _ytService.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final r = await _ytService.searchMusic(q);
      setState(() => _results = r);
    } catch (_) {
      setState(() => _error = 'Gagal memuat hasil. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToFavorite(MusicItem item) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('liked_songs').upsert({
        'user_id': user.id,
        'youtube_id': item.id,
        'title': item.title,
        'author': item.author,
        'thumbnail': item.thumbnailUrl,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersimpan di Koleksi')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Future<void> _addToPlaylist(MusicItem item) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: LumaColors.darkSurface,
          title: const Text('Pilih Playlist', style: TextStyle(color: Colors.white)),
          content: FutureBuilder(
            future: Supabase.instance.client.from('playlists').select().eq('user_id', user.id).order('created_at'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              if (snapshot.hasError) return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
              
              final playlists = snapshot.data as List<dynamic>? ?? [];
              if (playlists.isEmpty) return const Text('Belum ada playlist.', style: TextStyle(color: Colors.white54));
              
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, i) {
                    final p = playlists[i];
                    return ListTile(
                      title: Text(p['name'], style: const TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(context); // close dialog
                        try {
                          await Supabase.instance.client.from('playlist_tracks').insert({
                            'playlist_id': p['id'],
                            'youtube_id': item.id,
                            'title': item.title,
                            'author': item.author,
                            'thumbnail': item.thumbnailUrl,
                          });
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ditambahkan ke ${p['name']}')));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan: $e')));
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      }
    );
  }

  void _showOptions(MusicItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LumaColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(item.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1),
                      Text(item.author, style: const TextStyle(color: LumaColors.darkTextSecondary), maxLines: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: LumaColors.darkDivider),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.white),
            title: const Text('Tambahkan ke Playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _addToPlaylist(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.white),
            title: const Text('Simpan ke Lagu yang Disukai', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _addToFavorite(item);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Cari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: LumaColors.darkTextPrimary),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Apa yang ingin kamu dengarkan?',
                hintStyle: const TextStyle(color: LumaColors.darkTextSecondary),
                prefixIcon: const Icon(Icons.search, color: LumaColors.darkTextPrimary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: LumaColors.darkTextPrimary),
                        onPressed: () {
                          _controller.clear();
                          setState(() { _results = []; _searched = false; });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: LumaColors.accent))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : !_searched
                        ? const Center(child: Text('Cari lagu, artis, atau podcast', style: TextStyle(color: LumaColors.darkTextSecondary)))
                        : _results.isEmpty
                            ? const Center(child: Text('Tidak ditemukan', style: TextStyle(color: LumaColors.darkTextSecondary)))
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _results.length,
                                itemBuilder: (context, i) {
                                  final item = _results[i];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        item.thumbnailUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: Colors.grey),
                                      ),
                                    ),
                                    title: Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(item.author, style: const TextStyle(color: LumaColors.darkTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                                      onPressed: () => _showOptions(item),
                                    ),
                                    onTap: () {
                                      ref.read(playerProvider.notifier).play(_results, i);
                                    },
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}
