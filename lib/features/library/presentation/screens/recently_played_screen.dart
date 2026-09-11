import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/luma_list_skeleton.dart';
import '../../../../features/player/presentation/widgets/track_row.dart';

class RecentlyPlayedScreen extends ConsumerStatefulWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  ConsumerState<RecentlyPlayedScreen> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends ConsumerState<RecentlyPlayedScreen> {
  final _supabase = Supabase.instance.client;
  List<MusicItem> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _supabase
          .from('recently_played')
          .select()
          .eq('user_id', user.id)
          .order('played_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _tracks = (res as List<dynamic>)
              .map((row) => MusicItem.fromMap(row as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat riwayat: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        backgroundColor: LumaColors.darkBg,
        elevation: 0,
        title: const Text(
          'Riwayat Didengar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LumaListSkeleton(count: 8);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _fetchHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tracks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text(
              'Belum ada riwayat',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Lagu yang kamu dengarkan akan muncul di sini.',
              style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: LumaColors.accent,
      backgroundColor: LumaColors.darkSurface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final track = _tracks[index];
          return TrackRow(
            item: track,
            onTap: () {
              ref.read(playerProvider.notifier).play(_tracks, index);
            },
          );
        },
      ),
    );
  }
}
