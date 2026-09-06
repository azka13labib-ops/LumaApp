import 'package:flutter/material.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../player/presentation/screens/player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Lagu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Judul, artis, atau penggalan lirik...',
                prefixIcon: Icon(Icons.search, color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                        onPressed: () { _controller.clear(); setState(() {}); },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: _buildBody(cs, tt, isDark),
    );
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt, bool isDark) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_error!, textAlign: TextAlign.center, style: tt.bodyMedium),
        ),
      );
    }
    if (!_searched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Ketik lagu, artis, atau lirik lagu favoritmu.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium,
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(child: Text('Tidak ada hasil ditemukan.', style: tt.bodyMedium));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(indent: 76, endIndent: 16, height: 1),
      itemBuilder: (context, i) {
        final item = _results[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              item.thumbnailUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48, height: 48,
                color: isDark ? LumaColors.darkSurface : LumaColors.lightSurface,
                child: Icon(Icons.music_note, size: 20, color: cs.primary),
              ),
            ),
          ),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: -0.2)),
          subtitle: Text(item.author, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerScreen(playlist: _results, initialIndex: i),
            ),
          ),
        );
      },
    );
  }
}
