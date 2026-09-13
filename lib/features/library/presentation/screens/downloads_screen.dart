import 'package:flutter/material.dart';
import '../../../../core/widgets/luma_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}
class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  List<MusicItem> _items = [];
  bool _loading = true;
  int _totalSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await OfflineCacheService.instance.listCached();
    final size = await OfflineCacheService.instance.getTotalSizeBytes();
    if (mounted) {
      setState(() {
        _items = list;
        _totalSizeBytes = size;
        _loading = false;
      });
    }
  }

  Future<void> _remove(MusicItem item) async {
    await OfflineCacheService.instance.remove(item.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(_modernSnack('${item.title} dihapus', isError: false));
    }
  }

  void _playAll() {
    if (_items.isEmpty) return;
    ref.read(playerProvider.notifier).play(_items, 0);
  }

  void _shuffleAll() {
    if (_items.isEmpty) return;
    final shuffled = List<MusicItem>.from(_items)..shuffle();
    ref.read(playerProvider.notifier).play(shuffled, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white : LumaColors.lightTextPrimary);
    final textSecondary = theme.textTheme.labelSmall?.color ?? (isDark ? LumaColors.darkTextSecondary : LumaColors.lightTextSecondary);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Unduhan',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _playAll,
            icon: Icon(Icons.play_arrow_rounded, size: 18, color: theme.colorScheme.primary),
            label: Text('Putar', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
      body: _loading
          ? const LumaListSkeleton(count: 5, showTrailing: true)
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_outlined,
                            color: isDark ? Colors.white24 : Colors.black26, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada lagu tersimpan.\nUnduh dari layar pemutar agar bisa diputar offline.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      // Header stats + Play All / Shuffle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              '${_items.length} lagu · ${OfflineCacheService.formatBytes(_totalSizeBytes)}',
                              style: TextStyle(color: textSecondary, fontSize: 12),
                            ),
                            const Spacer(),
                            _playAllButton(theme),
                            const SizedBox(width: 8),
                            _shuffleButton(theme, isDark, textPrimary),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                color: Colors.red.shade900,
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) => _remove(item),
                              child: ListTile(
                                onTap: () => ref.read(playerProvider.notifier).play(_items, i),
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
                                  style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      item.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: textSecondary, fontSize: 12),
                                    ),
                                    if (item.fileSizeBytes != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF27272A) : LumaColors.lightBorder,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          OfflineCacheService.formatBytes(item.fileSizeBytes!),
                                          style: TextStyle(color: textSecondary, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item.fileSizeBytes != null && item.fileSizeBytes! > 0)
                                      Icon(Icons.download_done_rounded, color: theme.colorScheme.primary, size: 20),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_rounded,
                                          color: isDark ? Colors.white38 : LumaColors.lightTextMuted, size: 20),
                                      onPressed: () => _remove(item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _playAllButton(ThemeData theme) {
    return GestureDetector(
      onTap: _playAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: theme.colorScheme.onPrimary, size: 16),
            const SizedBox(width: 4),
            Text('Putar Semua',
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _shuffleButton(ThemeData theme, bool isDark, Color textPrimary) {
    return GestureDetector(
      onTap: _shuffleAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? LumaColors.darkSurface : LumaColors.lightSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shuffle_rounded, color: textPrimary, size: 16),
            const SizedBox(width: 4),
            Text('Acak', style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
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
          child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ],
    ),
    backgroundColor: const Color(0xFF18181B),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}