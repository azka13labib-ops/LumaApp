import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await OfflineCacheService.instance.listCached();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  Future<void> _remove(MusicItem item) async {
    await OfflineCacheService.instance.remove(item.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${item.title} dihapus dari unduhan'),
        backgroundColor: LumaColors.darkSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
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
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: LumaColors.accent, strokeWidth: 2),
            )
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
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Text(
                            '${_items.length} lagu · cache lokal (URL sumber bisa kedaluwarsa saat unduh ulang)',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        );
                      }
                      final item = _items[i - 1];
                      return ListTile(
                        onTap: () => ref.read(playerProvider.notifier).play(_items, i - 1),
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
                        subtitle: Text(
                          item.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38),
                          onPressed: () => _remove(item),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
