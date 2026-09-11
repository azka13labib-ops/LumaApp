import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';
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

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _ytService.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    _focusNode.unfocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cari', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: false,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
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
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Lagu, artis, atau album',
                      hintStyle: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: LumaColors.darkTextSecondary),
                      suffixIcon: (_loading || _isDebouncing)
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: LumaColors.accent),
                              ),
                            )
                          : _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: LumaColors.darkTextSecondary),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {
                                      _results = [];
                                      _searched = false;
                                      _error = null;
                                      _isDebouncing = false;
                                    });
                                  })
                              : null,
                      filled: true, fillColor: LumaColors.darkSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: LumaColors.accent, width: 1.5),
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
    if (_loading) return const LumaListSkeleton(count: 8);

    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: () => _search(_controller.text),
              child: const Text('Coba lagi', style: TextStyle(color: LumaColors.accent))),
          ],
        ),
      ));
    }

    if (!_searched) {
      const suggestions = [
        'Bernadya',
        'Tulus',
        'Mahalini',
        'Juicy Luicy',
        'Pop Indonesia',
        'Nadin Amizah',
        'Lofi Chill',
        'Top Hits',
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pencarian Populer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((s) {
                return ActionChip(
                  backgroundColor: LumaColors.darkSurface,
                  side: const BorderSide(color: Colors.white12),
                  label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  onPressed: () {
                    _controller.text = s;
                    _search(s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 36),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, color: Colors.white12, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Ketik lagu, artis, atau album\nuntuk mulai mencari',
                    style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_off_rounded, color: Colors.white12, size: 56),
          const SizedBox(height: 16),
          Text('"${_controller.text}" tidak ditemukan',
            style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Coba kata kunci lain', style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13)),
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
