import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';

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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
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
                    child: const Icon(Icons.music_note, color: Colors.white30, size: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.author,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (showDownload)
              _DownloadTrackButton(item: item),
            if (!showDownload)
              trailing ??
                  const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
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
                color: LumaColors.accent,
                value: progress != null ? progress.clamp(0.0, 1.0) : null,
              )
            : Icon(
                isCached ? Icons.download_done_rounded : Icons.download_rounded,
                color: isCached ? LumaColors.accent : Colors.white54,
                size: 20,
              ),
        onPressed: () async {
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
          if (!context.mounted) return;
          final nowCached = await OfflineCacheService.instance.isCached(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            _modernSnack(
              nowCached ? 'Berhasil diunduh 🎵' : 'Gagal mengunduh',
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
          color: isError ? Colors.red.shade300 : LumaColors.accent,
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