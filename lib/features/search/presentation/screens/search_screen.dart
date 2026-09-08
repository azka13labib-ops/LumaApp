import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/player_provider.dart';
import 'artist_screen.dart';
import '../widgets/playlist_picker_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final YouTubeService _ytService = YouTubeService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<MusicItem> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _ytService.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    _focusNode.unfocus();
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final r = await _ytService.searchMusic(q);
      if (mounted) setState(() => _results = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat hasil. Periksa koneksi.');
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
        'artist': item.author,
        'cover_url': item.thumbnailUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Disimpan ke Lagu Disukai'),
          backgroundColor: LumaColors.darkSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal: $e'), backgroundColor: Colors.red.shade900, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _addToPlaylist(MusicItem item) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => PlaylistPickerSheet(item: item, userId: user.id),
    );
  }

  void _showOptions(MusicItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(item.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: LumaColors.darkSurface,
                        child: const Icon(Icons.music_note, color: Colors.white38)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item.author, style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2A2A2A)),
            _OptionTile(icon: Icons.favorite_border_rounded, label: 'Simpan ke Lagu Disukai',
              onTap: () { Navigator.pop(ctx); _addToFavorite(item); }),
            _OptionTile(icon: Icons.playlist_add_rounded, label: 'Tambah ke Playlist',
              onTap: () { Navigator.pop(ctx); _addToPlaylist(item); }),
            _OptionTile(icon: Icons.queue_music_rounded, label: 'Putar Berikutnya',
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerProvider.notifier).playNext(item);
              }),
            _OptionTile(icon: Icons.playlist_play_rounded, label: 'Tambah ke Antrian',
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerProvider.notifier).addToQueue(item);
              }),
            _OptionTile(icon: Icons.person_outline_rounded, label: 'Lihat Artis',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ArtistScreen(artistName: item.author),
                ));
              }),
            _OptionTile(icon: Icons.download_rounded, label: 'Unduh',
              onTap: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Mengunduh…'),
                  backgroundColor: LumaColors.darkSurface,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ));
                final ok = await ref.read(playerProvider.notifier).downloadTrack(item);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Berhasil diunduh' : 'Gagal mengunduh lagu'),
                  backgroundColor: ok ? LumaColors.darkSurface : Colors.red.shade900,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ));
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cari', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Lagu, artis, atau album',
                      hintStyle: const TextStyle(color: Colors.black45, fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.black54),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.black54),
                              onPressed: () { _controller.clear(); setState(() { _results = []; _searched = false; _error = null; }); })
                          : null,
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: LumaColors.accent, strokeWidth: 2));

    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: () => _search(_controller.text),
              child: const Text('Coba lagi', style: TextStyle(color: LumaColors.accent))),
          ],
        ),
      ));
    }

    if (!_searched) {
      return const Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, color: Colors.white12, size: 56),
          SizedBox(height: 16),
          Text('Ketik nama lagu atau artis\ndi kotak pencarian',
            style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14), textAlign: TextAlign.center),
        ],
      ));
    }

    if (_results.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_off_rounded, color: Colors.white12, size: 56),
          const SizedBox(height: 16),
          Text('"${_controller.text}" tidak ditemukan',
            style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Coba kata kunci lain', style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 160),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final item = _results[i];
        return _TrackRow(
          item: item,
          onTap: () => ref.read(playerProvider.notifier).play(_results, i),
          onMore: () => _showOptions(item),
        );
      },
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.item, required this.onTap, required this.onMore});
  final MusicItem item;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(item.thumbnailUrl, width: 52, height: 52, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: LumaColors.darkSurface,
                  child: const Icon(Icons.music_note, color: Colors.white38, size: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(item.author, style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            SizedBox(width: 48, height: 48,
              child: IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 20), onPressed: onMore)),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }
}
