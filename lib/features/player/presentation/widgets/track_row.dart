import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_equalizer_bars.dart';
import '../../../../core/widgets/interactive_scale_button.dart';
import '../../../search/presentation/screens/artist_screen.dart';
import '../../../search/presentation/widgets/playlist_picker_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TrackRow extends ConsumerWidget {
  const TrackRow({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
    this.showDownload = false,
  });

  final MusicItem item;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showDownload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? LumaColors.darkTextPrimary : LumaColors.lightTextPrimary;
    final textSecondary = isDark ? LumaColors.darkTextSecondary : LumaColors.lightTextSecondary;

    final playerState = ref.watch(playerProvider);
    final isCurrent = playerState.current?.id == item.id;
    final isPlaying = isCurrent && playerState.isPlaying;

    return InteractiveScaleButton(
      pressedScale: 0.94,
      onTap: onTap,
      onLongPress: () => _showTrackMenu(context, ref, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
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
                          color: isDark ? Colors.white30 : LumaColors.lightTextMuted, size: 20),
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: AnimatedEqualizerBars(
                        isPlaying: isPlaying,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: isCurrent
                          ? (isDark ? Colors.white : const Color(0xFF09090B))
                          : textPrimary,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.author,
                    style: TextStyle(
                      color: isCurrent ? textPrimary : textSecondary,
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showDownload)
              _DownloadTrackButton(item: item),
            if (!showDownload)
              trailing ??
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded,
                        color: isDark ? Colors.white54 : LumaColors.lightTextSecondary, size: 20),
                    onPressed: () => _showTrackMenu(context, ref, item),
                  ),
          ],
        ),
      ),
    );
  }

  void _showTrackMenu(BuildContext context, WidgetRef ref, MusicItem item) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? LumaColors.darkSurface : Colors.white;
    final textPrimary = isDark ? Colors.white : LumaColors.lightTextPrimary;
    final textSecondary = isDark ? LumaColors.darkTextSecondary : LumaColors.lightTextSecondary;
    final iconColor = isDark ? Colors.white : const Color(0xFF18181B);
    final dividerColor = isDark ? const Color(0xFF2A2A2A) : LumaColors.lightDivider;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : LumaColors.lightDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: item.thumbnailUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        color: isDark ? const Color(0xFF222222) : LumaColors.lightSurface,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: isDark ? const Color(0xFF222222) : LumaColors.lightSurface,
                        child: Icon(Icons.music_note, color: isDark ? Colors.white24 : LumaColors.lightTextMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.author,
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
                ],
              ),
            ),
            Divider(color: dividerColor, height: 1),
            ListTile(
              leading: Icon(Icons.playlist_play_rounded, color: iconColor),
              title: Text('Putar Berikutnya', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerProvider.notifier).playNext(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  _modernSnack('Akan diputar berikutnya', isError: false),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.queue_music_rounded, color: iconColor),
              title: Text('Tambahkan ke Antrean', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerProvider.notifier).addToQueue(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  _modernSnack('Ditambahkan ke antrean', isError: false),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_add_rounded, color: iconColor),
              title: Text('Tambah ke Playlist', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: sheetBg,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => PlaylistPickerSheet(item: item, userId: user.id),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _modernSnack('Silakan login untuk menambah ke playlist', isError: true),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.download_rounded, color: iconColor),
              title: Text('Unduh Lagu', style: TextStyle(color: textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                final isCached = await OfflineCacheService.instance.isCached(item.id);
                if (isCached) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      _modernSnack('Lagu sudah tersimpan offline', isError: false),
                    );
                  }
                  return;
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _modernSnack('Mengunduh lagu...', isError: false),
                  );
                }
                await ref.read(playerProvider.notifier).downloadTrack(item);
                final nowCached = await OfflineCacheService.instance.isCached(item.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  _modernSnack(
                    nowCached ? 'Lagu berhasil diunduh' : 'Gagal mengunduh lagu',
                    isError: !nowCached,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person_rounded, color: iconColor),
              title: Text('Lihat Artis', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArtistScreen(artistName: item.author)),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DownloadTrackButton extends ConsumerWidget {
  const _DownloadTrackButton({required this.item});
  final MusicItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? Colors.white : const Color(0xFF18181B);
    final inactiveColor = isDark ? Colors.white54 : LumaColors.lightTextMuted;
    final isCached = ref.watch(playerProvider).isCached;
    final isDownloading = ref.watch(playerProvider).isDownloading;
    final progress = ref.watch(playerProvider).downloadingProgress;
    final state = ref.watch(playerProvider);

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: isDownloading && state.current?.id == item.id
            ? CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
                value: progress?.clamp(0.0, 1.0),
              )
            : Icon(
                isCached ? Icons.download_done_rounded : Icons.download_rounded,
                color: isCached ? accentColor : inactiveColor,
                size: 20,
              ),
        onPressed: () async {
          HapticFeedback.lightImpact();
          if (isCached) {
            ScaffoldMessenger.of(context).showSnackBar(
              _modernSnack('Lagu sudah tersimpan', isError: false),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            _modernSnack('Mengunduh…', isError: false),
          );
          await ref.read(playerProvider.notifier).downloadTrack(item);
          final nowCached = await OfflineCacheService.instance.isCached(item.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            _modernSnack(
              nowCached ? 'Berhasil diunduh' : 'Gagal mengunduh',
              isError: !nowCached,
            ),
          );
        },
      ),
    );
  }
}

SnackBar _modernSnack(String msg, {bool isError = false}) {
  return SnackBar(
    content: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
          color: isError ? Colors.red.shade300 : Colors.white,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    ),
    backgroundColor: LumaColors.darkSurface,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}