import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../player/presentation/widgets/track_row.dart';
import '../../../../core/widgets/luma_list_skeleton.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final YouTubeService _ytService = YouTubeService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isDebouncing = false;
  List<MusicItem> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  // History disimpan di static agar bertahan selama sesi app
  static final List<String> _searchHistory = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _ytService.dispose();
    super.dispose();
  }

  void _addToHistory(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _searchHistory.remove(trimmed);
      _searchHistory.insert(0, trimmed);
      if (_searchHistory.length > 10) _searchHistory.removeLast();
    });
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    _focusNode.unfocus();
    _addToHistory(q);
    setState(() { _loading = true; _error = null; _searched = true; _isDebouncing = false; });
    try {
      final r = await _ytService.searchMusic(q);
      if (mounted) setState(() => _results = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat hasil. Periksa koneksi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _results = [];
      _searched = false;
      _error = null;
      _isDebouncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;
    final surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cari', style: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: false,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    onChanged: (v) {
                      setState(() {
                        _isDebouncing = v.trim().length >= 2;
                      });
                      _debounce?.cancel();
                      if (v.trim().length >= 2) {
                        _debounce = Timer(const Duration(milliseconds: 500), () => _search(v));
                      } else {
                        setState(() => _isDebouncing = false);
                        if (v.isEmpty) {
                          setState(() { _searched = false; _results = []; });
                        }
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Lagu, artis, atau album',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
                      suffixIcon: (_loading || _isDebouncing)
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                              ),
                            )
                          : _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, color: textSecondary),
                                  onPressed: _clearSearch)
                              : null,
                      filled: true, fillColor: surfaceColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;
    final surfaceColor = theme.colorScheme.surface;

    if (_loading) return const LumaListSkeleton(count: 8);

    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: isDark ? Colors.white24 : Colors.black26, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: textPrimary, fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: () => _search(_controller.text),
              child: Text('Coba lagi', style: TextStyle(color: theme.colorScheme.primary))),
          ],
        ),
      ));
    }

    if (!_searched) {
      const suggestions = [
        'Bernadya', 'Tulus', 'Mahalini', 'Juicy Luicy',
        'Pop Indonesia', 'Nadin Amizah', 'Lofi Chill', 'Top Hits',
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Riwayat Pencarian
            if (_searchHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Riwayat', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => setState(() => _searchHistory.clear()),
                    child: Text('Hapus semua', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: List.generate(_searchHistory.length, (i) {
                      final q = _searchHistory[i];
                      final isLast = i == _searchHistory.length - 1;
                      return InkWell(
                        onTap: () {
                          _controller.text = q;
                          _search(q);
                        },
                        child: Container(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 18, color: textSecondary.withOpacity(0.7)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: isLast ? null : Border(
                                      bottom: BorderSide(color: theme.dividerColor.withOpacity(0.15), width: 0.5),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(q, style: TextStyle(color: textPrimary, fontSize: 15)),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close_rounded, size: 16, color: textSecondary.withOpacity(0.5)),
                                        onPressed: () => setState(() => _searchHistory.remove(q)),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        splashRadius: 16,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Pencarian Populer
            Text('Pencarian Populer', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((s) {
                return ActionChip(
                  avatar: Icon(Icons.trending_up_rounded, size: 16, color: theme.colorScheme.primary),
                  backgroundColor: surfaceColor,
                  side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
                  label: Text(s, style: TextStyle(color: textPrimary, fontSize: 13)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _controller.text = s;
                    _search(s);
                  },
                );
              }).toList(),
            ),

            if (_searchHistory.isEmpty) ...[
              const SizedBox(height: 36),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, color: theme.dividerColor, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Ketik lagu, artis, atau album\nuntuk mulai mencari',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_off_rounded, color: theme.dividerColor, size: 56),
          const SizedBox(height: 16),
          Text('"${_controller.text}" tidak ditemukan',
            style: TextStyle(color: textPrimary, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Coba kata kunci lain', style: TextStyle(color: textSecondary, fontSize: 13)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 160),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final item = _results[i];
        return TrackRow(
          item: item,
          onTap: () => ref.read(playerProvider.notifier).play(_results, i),
          showDownload: true,
        );
      },
    );
  }
}
