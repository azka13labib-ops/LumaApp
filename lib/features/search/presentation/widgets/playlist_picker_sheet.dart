import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';

class PlaylistPickerSheet extends StatelessWidget {
  const PlaylistPickerSheet({super.key, required this.item, required this.userId});

  final MusicItem item;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              alignment: Alignment.center,
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text('Tambah ke Playlist',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          FutureBuilder(
            future: Supabase.instance.client
                .from('playlists')
                .select()
                .eq('user_id', userId)
                .order('created_at'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: LumaColors.accent, strokeWidth: 2)));
              }
              if (snapshot.hasError) {
                return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Gagal memuat playlist',
                        style: TextStyle(color: Colors.red.shade300)));
              }
              final playlists = snapshot.data as List<dynamic>? ?? [];
              if (playlists.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Column(children: [
                      Icon(Icons.playlist_add_rounded, color: Colors.white24, size: 40),
                      SizedBox(height: 12),
                      Text('Belum ada playlist.\nBuat playlist dari tab +',
                          style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14),
                          textAlign: TextAlign.center),
                    ])));
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: playlists.length,
                itemBuilder: (context, i) {
                  final p = playlists[i];
                  return ListTile(
                    leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: LumaColors.darkSurface, borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.queue_music_rounded,
                            color: Colors.white38, size: 20)),
                    title: Text(p['name'] ?? 'Playlist',
                        style: const TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await Supabase.instance.client.from('playlist_items').insert({
                          'playlist_id': p['id'],
                          'youtube_id': item.id,
                          'title': item.title,
                          'artist': item.author,
                          'cover_url': item.thumbnailUrl,
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Ditambahkan ke ${p['name']}'),
                            backgroundColor: LumaColors.darkSurface,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Gagal: $e'),
                            backgroundColor: Colors.red.shade900,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
