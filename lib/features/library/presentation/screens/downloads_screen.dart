import 'package:flutter/material.dart';
import '../../../../core/widgets/luma_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';

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
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Unduhan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _playAll,
            icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
            label: const Text('Putar', style: TextStyle(color: Colors.white, fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
      body: _loading
          ? const LumaListSkeleton(count: 5, showTrailing: true)
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_outlined, color: Colors.white24, size: 56),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada lagu tersimpan.\nUnduh dari layar pemutar agar bisa diputar offline.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: LumaColors.accent,
                  backgroundColor: LumaColors.darkSurface,
                  child: Column(
                    children: [
                      // Header stats + Play All / Shuffle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              '${_items.length} lagu · ${OfflineCacheService.formatBytes(_totalSizeBytes)}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const Spacer(),
                            _playAllButton(),
                            const SizedBox(width: 8),
                            _shuffleButton(),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFF2A2A2A)),
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
                                  child: Image.network(
                                    item.thumbnailUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: LumaColors.darkSurface,
                                      child: const Icon(Icons.music_note, color: Colors.white38),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      item.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12),
                                    ),
                                    if (item.fileSizeBytes != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: LumaColors.darkSurface,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          OfflineCacheService.formatBytes(item.fileSizeBytes!),
                                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item.fileSizeBytes != null && item.fileSizeBytes! > 0)
                                      Icon(Icons.download_done_rounded, color: LumaColors.accent, size: 20),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
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

  Widget _playAllButton() {
    return GestureDetector(
      onTap: _playAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: LumaColors.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Putar Semua', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _shuffleButton() {
    return GestureDetector(
      onTap: _shuffleAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: LumaColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shuffle_rounded, color: Colors.white54, size: 16),
            SizedBox(width: 4),
            Text('Acak', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
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
          color: isError ? Colors.red.shade300 : LumaColors.accent,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ],
    ),
    backgroundColor: LumaColors.darkSurface,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}