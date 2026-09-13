import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/youtube_service.dart';

class PlaylistPickerSheet extends StatelessWidget {
  const PlaylistPickerSheet({super.key, required this.item, required this.userId});

  final MusicItem item;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

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
                      color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text('Tambah ke Playlist',
                style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          Divider(height: 1, color: theme.dividerColor),
          FutureBuilder(
            future: Supabase.instance.client
                .from('playlists')
                .select()
                .eq('user_id', userId)
                .order('created_at'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Skeletonizer(
                  enabled: true,
                  effect: ShimmerEffect(
                    baseColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade300,
                    highlightColor: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade100,
                    duration: const Duration(milliseconds: 1200),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (_, __) => ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Container(height: 13, width: 140, color: textPrimary),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Gagal memuat playlist',
                        style: TextStyle(color: Colors.red.shade300)));
              }
              final playlists = snapshot.data as List<dynamic>? ?? [];
              if (playlists.isEmpty) {
                return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                        child: Column(children: [
                      Icon(Icons.playlist_add_rounded, color: theme.dividerColor, size: 40),
                      const SizedBox(height: 12),
                      Text('Belum ada playlist.\nBuat playlist dari tab +',
                          style: TextStyle(color: textSecondary, fontSize: 14),
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
                            color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(4)),
                        child: Icon(Icons.queue_music_rounded,
                            color: textSecondary, size: 20)),
                    title: Text(p['name'] ?? 'Playlist',
                        style: TextStyle(color: textPrimary, fontSize: 15)),
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
                            backgroundColor: theme.colorScheme.surface,
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
