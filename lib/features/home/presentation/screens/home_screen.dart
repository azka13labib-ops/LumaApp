import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../search/presentation/screens/artist_screen.dart';
import '../../../../features/player/presentation/widgets/track_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<MusicItem> _recentlyPlayed = [];
  List<MusicItem> _likedSongs = [];
  List<String> _artists = [];
  List<MusicItem> _cachedTracks = [];
  bool _loading = true;
  bool _isOffline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() { _loading = false; _error = 'Tidak ada sesi login.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final recentRes = await _supabase
          .from('recently_played')
          .select()
          .eq('user_id', user.id)
          .order('played_at', ascending: false)
          .limit(10);

      final likedRes = await _supabase
          .from('liked_songs')
          .select()
          .eq('user_id', user.id)
          .order('liked_at', ascending: false)
          .limit(8);

      final cached = await OfflineCacheService.instance.listCached();

      if (mounted) {
        final recent = (recentRes as List)
            .map((e) => MusicItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        final liked = (likedRes as List)
            .map((e) => MusicItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();

        final seen = <String>{};
        final artists = <String>[];
        for (final t in [...recent, ...liked]) {
          final name = t.author.trim();
          if (name.isEmpty) continue;
          final key = name.toLowerCase();
          if (!seen.add(key)) continue;
          artists.add(name);
          if (artists.length >= 12) break;
        }

        setState(() {
          _recentlyPlayed = recent;
          _likedSongs = liked;
          _artists = artists;
          _cachedTracks = cached;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen error: $e');
      final cached = await OfflineCacheService.instance.listCached();
      if (mounted) {
        setState(() {
          _cachedTracks = cached;
          _loading = false;
          _error = null;
          _isOffline = true;
        });
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Offline banner
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A3A1A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Color(0xFF88FF88), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Mode Offline — ${_cachedTracks.length} lagu tersedia',
                      style: const TextStyle(color: Color(0xFF88FF88), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            // Top bar with greeting + avatar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: LumaColors.accent.withValues(alpha: 0.3),
                      child: Text(
                        initial,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Body
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: LumaColors.accent, strokeWidth: 2));

    if (_error != null && _cachedTracks.isEmpty && _recentlyPlayed.isEmpty && _likedSongs.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.headphones_rounded, color: Colors.white12, size: 64),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _fetchData,
            child: const Text('Coba lagi', style: TextStyle(color: LumaColors.accent)),
          ),
        ]),
      ));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: LumaColors.accent,
      backgroundColor: LumaColors.darkSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // If offline, display the cached tracks as a vertical list (primary content)
            if (_isOffline) ...[
              if (_cachedTracks.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text('Tersimpan Offline',
                    style: TextStyle(color: LumaColors.accent, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cachedTracks.length,
                  itemBuilder: (context, i) => TrackRow(
                    item: _cachedTracks[i],
                    onTap: () => ref.read(playerProvider.notifier).play(_cachedTracks, i),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.white12, size: 64),
                        SizedBox(height: 16),
                        Text('Kamu sedang offline dan belum ada lagu yang diunduh.',
                          style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 15), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ] else ...[
              // ONLINE MODE
              if (_recentlyPlayed.isEmpty && _likedSongs.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 48, 16, 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.headphones_rounded, color: Colors.white12, size: 64),
                    SizedBox(height: 16),
                    Text('Mulai cari lagu dan putar musik\nuntuk mengisi beranda kamu.',
                      style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 15), textAlign: TextAlign.center),
                  ]),
                ),

              if (_recentlyPlayed.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Baru saja didengar',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                height: 168,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentlyPlayed.length,
                  itemBuilder: (context, i) => _HorizontalCard(_recentlyPlayed[i], onTap: () {
                    ref.read(playerProvider.notifier).play(_recentlyPlayed, i);
                  }),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_likedSongs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('Lagu Disukai',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              ),
              SizedBox(
                height: 168,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _likedSongs.length,
                  itemBuilder: (context, i) => _HorizontalCard(_likedSongs[i], onTap: () {
                    ref.read(playerProvider.notifier).play(_likedSongs, i);
                  }),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_artists.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('Artis untukmu',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              ),
              SizedBox(
                height: 128,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _artists.length,
                  itemBuilder: (context, i) {
                    final name = _artists[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ArtistScreen(artistName: name)),
                      ),
                      child: Container(
                        width: 96,
                        margin: const EdgeInsets.only(right: 14),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: LumaColors.darkSurface,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}



// Horizontal card
class _HorizontalCard extends StatelessWidget {
  const _HorizontalCard(this.item, {required this.onTap});
  final MusicItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.thumbnailUrl,
                width: 120, height: 120, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120, height: 120, color: LumaColors.darkSurface,
                  child: const Icon(Icons.music_note, color: Colors.white24, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(item.title,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(item.author,
              style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}