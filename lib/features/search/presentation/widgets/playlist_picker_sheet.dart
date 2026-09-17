import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';

class PlaylistPickerSheet extends StatefulWidget {
  const PlaylistPickerSheet({
    super.key,
    required this.item,
    required this.userId,
  });

  final MusicItem item;
  final String userId;

  @override
  State<PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<PlaylistPickerSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _playlists = [];
  Set<String> _containingPlaylistIds = {};
  bool _isCreatingNew = false;
  bool _isSubmitting = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil semua playlist milik user
      final playlistsRes = await Supabase.instance.client
          .from('playlists')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      final playlistList = List<Map<String, dynamic>>.from(playlistsRes as List);

      // 2. Ambil informasi playlist mana saja yang sudah berisi lagu ini
      final playlistIds = playlistList.map((p) => p['id'] as String).toList();
      final Set<String> containing = {};

      if (playlistIds.isNotEmpty) {
        final itemsRes = await Supabase.instance.client
            .from('playlist_items')
            .select('playlist_id')
            .inFilter('playlist_id', playlistIds)
            .eq('youtube_id', widget.item.id);

        for (final row in itemsRes as List) {
          containing.add(row['playlist_id'].toString());
        }
      }

      if (mounted) {
        setState(() {
          _playlists = playlistList;
          _containingPlaylistIds = containing;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PlaylistPicker] load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addToPlaylist(Map<String, dynamic> playlist) async {
    final playlistId = playlist['id'].toString();
    final playlistName = playlist['name'] ?? 'Playlist';

    // Jika sudah ada, jangan tambahkan duplikat
    if (_containingPlaylistIds.contains(playlistId)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lagu ini sudah ada di $playlistName'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _containingPlaylistIds.add(playlistId);
    });

    try {
      await Supabase.instance.client.from('playlist_items').insert({
        'playlist_id': playlistId,
        'youtube_id': widget.item.id,
        'title': widget.item.title,
        'artist': widget.item.author,
        'cover_url': widget.item.thumbnailUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Berhasil ditambahkan ke $playlistName',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _containingPlaylistIds.remove(playlistId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan ke playlist: $e'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _createAndAddPlaylist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      // 1. Pastikan user profile ada
      try {
        await Supabase.instance.client.from('user_profiles').upsert({
          'id': widget.userId,
          'username': Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'User',
          'avatar_url': '',
        });
      } catch (_) {}

      // 2. Buat playlist baru
      final newPlaylistRes = await Supabase.instance.client.from('playlists').insert({
        'user_id': widget.userId,
        'name': name,
        'cover_url': widget.item.thumbnailUrl,
      }).select().single();

      final newPlaylistId = newPlaylistRes['id'].toString();

      // 3. Masukkan lagu ke playlist baru tersebut
      await Supabase.instance.client.from('playlist_items').insert({
        'playlist_id': newPlaylistId,
        'youtube_id': widget.item.id,
        'title': widget.item.title,
        'artist': widget.item.author,
        'cover_url': widget.item.thumbnailUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Playlist "$name" dibuat & lagu berhasil ditambahkan',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat playlist: $e'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : LumaColors.lightTextPrimary;
    final textSecondary = isDark ? LumaColors.darkTextSecondary : LumaColors.lightTextSecondary;
    final surfaceColor = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF2A2A2E) : LumaColors.lightDivider;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle Bar ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header Preview Lagu ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.item.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.white10),
                      errorWidget: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.white10,
                        child: const Icon(Icons.music_note_rounded, color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah ke Playlist',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.item.author,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: dividerColor),

            // ── Form Inline Pembuatan Playlist Baru ──
            if (_isCreatingNew)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF28282E) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Playlist Baru',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nama playlist...',
                          hintStyle: TextStyle(color: textSecondary),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() => _isCreatingNew = false);
                                    _nameController.clear();
                                  },
                            child: Text('Batal', style: TextStyle(color: textSecondary)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _createAndAddPlaylist,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Buat & Simpan', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              // ── Tombol "+ Buat Playlist Baru" ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: InkWell(
                  onTap: () => setState(() => _isCreatingNew = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28282E) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_rounded, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buat Playlist Baru',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Simpan lagu ini ke playlist baru',
                                style: TextStyle(color: textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Daftar Playlist ──
            Expanded(
              child: _isLoading
                  ? Skeletonizer(
                      enabled: true,
                      child: ListView.builder(
                        itemCount: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (_, __) => ListTile(
                          leading: Container(width: 48, height: 48, color: Colors.white12),
                          title: Container(height: 14, width: 120, color: Colors.white12),
                          subtitle: Container(height: 10, width: 60, color: Colors.white12),
                        ),
                      ),
                    )
                  : _playlists.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.queue_music_rounded, color: textSecondary.withValues(alpha: 0.4), size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada playlist',
                                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Klik tombol "+ Buat Playlist Baru" di atas untuk mulai membuat playlist pertama Anda.',
                                  style: TextStyle(color: textSecondary, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          itemCount: _playlists.length,
                          separatorBuilder: (_, __) => Divider(height: 1, indent: 70, color: dividerColor.withValues(alpha: 0.5)),
                          itemBuilder: (context, index) {
                            final p = _playlists[index];
                            final pid = p['id'].toString();
                            final isAlreadyIn = _containingPlaylistIds.contains(pid);
                            final coverUrl = p['cover_url'] as String?;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: coverUrl != null && coverUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: coverUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          width: 48,
                                          height: 48,
                                          color: isDark ? const Color(0xFF28282E) : Colors.grey.shade200,
                                          child: Icon(Icons.music_note_rounded, color: textSecondary),
                                        ),
                                      )
                                    : Container(
                                        width: 48,
                                        height: 48,
                                        color: isDark ? const Color(0xFF28282E) : Colors.grey.shade200,
                                        child: Icon(Icons.queue_music_rounded, color: textSecondary),
                                      ),
                              ),
                              title: Text(
                                p['name'] ?? 'Playlist',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                isAlreadyIn ? 'Sudah ada di playlist ini' : 'Ketuk untuk menambahkan',
                                style: TextStyle(
                                  color: isAlreadyIn ? const Color(0xFF10B981) : textSecondary,
                                  fontSize: 12,
                                  fontWeight: isAlreadyIn ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              trailing: isAlreadyIn
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 24,
                                    )
                                  : Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: textSecondary.withValues(alpha: 0.6),
                                      size: 24,
                                    ),
                              onTap: () => _addToPlaylist(p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
