import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../search/presentation/screens/artist_screen.dart';
import '../../../../features/player/presentation/widgets/track_row.dart';
import '../../../../core/widgets/luma_list_skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final _ytService = YouTubeService();

  List<MusicItem> _recentlyPlayed = [];
  List<MusicItem> _likedSongs = [];
  List<String> _artists = [];
  List<MusicItem> _cachedTracks = [];
  List<MusicItem> _recommendedSongs = [];

  bool _loading = true;
  bool _recommendedLoading = false;
  bool _isOffline = false;
  String? _error;

  String _selectedGenre = 'Populer';
  final List<String> _genres = const [
    'Populer',
    'Pop Indo',
    'Hits',
    'Santai',
    'Galau',
    'Lofi',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _ytService.dispose();
    super.dispose();
  }

  String _genreQuery(String genre) {
    return switch (genre) {
      'Pop Indo' => 'Pop Indonesia',
      'Hits' => 'Top Hits Indonesia',
      'Santai' => 'Akustik Santai Indonesia',
      'Galau' => 'Lagu Galau Indonesia',
      'Lofi' => 'Lofi Chill',
      _ => 'Lagu Populer Indonesia',
    };
  }

  Future<void> _fetchRecommended(String genre) async {
    setState(() => _recommendedLoading = true);
    try {
      final items = await _ytService.searchMusic(_genreQuery(genre));
      if (mounted) {
        setState(() {
          _recommendedSongs = items;
          _recommendedLoading = false;
        });
      }
    } catch (e) {
      debugPrint('fetchRecommended error: $e');
      if (mounted) setState(() => _recommendedLoading = false);
    }
  }

  Future<void> _fetchData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() { _loading = false; _error = 'Tidak ada sesi login.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final recentFuture = _supabase
          .from('recently_played')
          .select()
          .eq('user_id', user.id)
          .order('played_at', ascending: false)
          .limit(10);
      final likedFuture = _supabase
          .from('liked_songs')
          .select()
          .eq('user_id', user.id)
          .order('liked_at', ascending: false)
          .limit(8);
      final cachedFuture = OfflineCacheService.instance.listCached();
      final recommendedFuture = _ytService.searchMusic(_genreQuery(_selectedGenre));

      final results = await Future.wait<dynamic>([
        recentFuture,
        likedFuture,
        cachedFuture,
        recommendedFuture,
      ]);

      final recentRes = results[0] as List;
      final likedRes = results[1] as List;
      final cached = results[2] as List<MusicItem>;
      final recommended = results[3] as List<MusicItem>;

      if (mounted) {
        final recent = recentRes
            .map((e) => MusicItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        final liked = likedRes
            .map((e) => MusicItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();

        final seen = <String>{};
        final artists = <String>[];
        for (final t in [...recent, ...liked, ...recommended]) {
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
          _recommendedSongs = recommended;
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
    
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      'Mode Offline: ${_cachedTracks.length} lagu tersedia',
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
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: LumaColors.accent.withValues(alpha: 0.25),
                      child: Text(
                        initial,
                        style: const TextStyle(color: LumaColors.accent, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Genre Filter Chips (only when online)
            if (!_isOffline)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _genres.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final g = _genres[i];
                    final isSelected = g == _selectedGenre;
                    return ChoiceChip(
                      label: Text(g),
                      selected: isSelected,
                      selectedColor: LumaColors.accent,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected ? LumaColors.accent : theme.dividerColor,
                      ),
                      onSelected: (val) {
                        if (val && _selectedGenre != g) {
                          setState(() => _selectedGenre = g);
                          _fetchRecommended(g);
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            // Body
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _HomeSkeleton();

    if (_error != null && _cachedTracks.isEmpty && _recentlyPlayed.isEmpty && _likedSongs.isEmpty && _recommendedSongs.isEmpty) {
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
              if (_recentlyPlayed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Baru saja didengar',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                ),
                const SizedBox(height: 12),
                
                // Hero card for the first recently played
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _HeroCard(_recentlyPlayed.first, onTap: () {
                    ref.read(playerProvider.notifier).play(_recentlyPlayed, 0);
                  }),
                ),
                const SizedBox(height: 16),
                
                if (_recentlyPlayed.length > 1)
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recentlyPlayed.length - 1,
                      itemBuilder: (context, i) => _HorizontalCard(_recentlyPlayed[i + 1], onTap: () {
                        ref.read(playerProvider.notifier).play(_recentlyPlayed, i + 1);
                      }),
                    ),
                  ),
                const SizedBox(height: 32),
              ],

              if (_likedSongs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('Lagu Disukai',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                ),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _likedSongs.length,
                    itemBuilder: (context, i) => _HorizontalCard(_likedSongs[i], onTap: () {
                      ref.read(playerProvider.notifier).play(_likedSongs, i);
                    }),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_artists.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('Artis untukmu',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                ),
                SizedBox(
                  height: 128,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _artists.length,
                    itemBuilder: (context, i) {
                      final name = _artists[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
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
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
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
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
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
                const SizedBox(height: 20),
              ],

              // REKOMENDASI POPULER / PILIHAN (ALWAYS VISIBLE)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lagu $_selectedGenre',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_recommendedLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LumaColors.accent,
                        ),
                      ),
                  ],
                ),
              ),

              if (_recommendedLoading && _recommendedSongs.isEmpty)
                const LumaListSkeleton(count: 6)
              else if (_recommendedSongs.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recommendedSongs.length,
                  itemBuilder: (context, i) {
                    final item = _recommendedSongs[i];
                    return TrackRow(
                      item: item,
                      onTap: () => ref.read(playerProvider.notifier).play(_recommendedSongs, i),
                      showDownload: true,
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Belum ada lagu untuk kategori ini',
                          style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _fetchRecommended(_selectedGenre),
                          child: const Text('Muat Ulang', style: TextStyle(color: LumaColors.accent)),
                        ),
                      ],
                    ),
                  ),
                ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 104,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.thumbnailUrl,
                width: 104, height: 104, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 104, height: 104, color: Theme.of(context).colorScheme.surface,
                  child: Icon(Icons.music_note, color: Theme.of(context).dividerColor, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(item.title,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(item.author,
              style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// Hero card
class _HeroCard extends StatelessWidget {
  const _HeroCard(this.item, {required this.onTap});
  final MusicItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(item.thumbnailUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: LumaColors.accent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    item.author,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading for the home screen
// ---------------------------------------------------------------------------
class _HomeSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFF1E1E1E),
        highlightColor: Color(0xFF2E2E2E),
        duration: Duration(milliseconds: 1200),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 160),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1 header
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Baru saja didengar',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            // Horizontal cards row
            SizedBox(
              height: 168,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (_, __) => Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(width: 120, height: 120, color: LumaColors.darkSurface),
                      ),
                      const SizedBox(height: 6),
                      Container(height: 11, width: 90, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(height: 10, width: 60, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Section 2 header
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Lagu Disukai',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 168,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (_, __) => Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(width: 120, height: 120, color: LumaColors.darkSurface),
                      ),
                      const SizedBox(height: 6),
                      Container(height: 11, width: 90, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(height: 10, width: 60, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Section 3 – artist circles
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Artis untukmu',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 128,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (_, __) => Container(
                  width: 96,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 40, backgroundColor: LumaColors.darkSurface),
                      const SizedBox(height: 8),
                      Container(height: 11, width: 64, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}