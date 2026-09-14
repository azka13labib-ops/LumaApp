import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/widgets/interactive_scale_button.dart';
import '../../../profile/presentation/screens/profile_settings_screen.dart';
import '../../../search/presentation/screens/artist_screen.dart';
import 'package:flutter/cupertino.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white : LumaColors.lightTextPrimary);

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
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : LumaColors.lightSurface,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF27272A) : LumaColors.lightBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        color: isDark ? Colors.white70 : LumaColors.lightTextPrimary,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Mode Offline: ${_cachedTracks.length} lagu tersedia',
                      style: TextStyle(
                          color: isDark ? Colors.white70 : LumaColors.lightTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
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
                        CupertinoPageRoute(builder: (_) => const ProfileSettingsScreen())),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark ? const Color(0xFF27272A) : LumaColors.lightBorder,
                      child: Text(
                        initial,
                        style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
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
                      selectedColor: isDark ? Colors.white : const Color(0xFF18181B),
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF18181B))
                            : theme.dividerColor,
                      ),
                      onSelected: (val) {
                        if (val && _selectedGenre != g) {
                          HapticFeedback.selectionClick();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white : LumaColors.lightTextPrimary);
    final textSecondary = isDark ? LumaColors.darkTextSecondary : LumaColors.lightTextSecondary;

    if (_loading) return _HomeSkeleton();

    if (_error != null && _cachedTracks.isEmpty && _recentlyPlayed.isEmpty && _likedSongs.isEmpty && _recommendedSongs.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.headphones_rounded,
              color: isDark ? Colors.white12 : Colors.black12, size: 64),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: textSecondary, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _fetchData,
            child: Text('Coba lagi', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ]),
      ));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: theme.colorScheme.primary,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text('Tersimpan Offline',
                    style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
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
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            color: isDark ? Colors.white12 : Colors.black12, size: 64),
                        const SizedBox(height: 16),
                        Text('Kamu sedang offline dan belum ada lagu yang diunduh.',
                          style: TextStyle(color: textSecondary, fontSize: 15), textAlign: TextAlign.center),
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
                    height: 200,
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
                  height: 200,
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
                      return InteractiveScaleButton(
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (_) => ArtistScreen(artistName: name)),
                        ),
                        pressedScale: 0.95,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -16,
                                bottom: -16,
                                child: Icon(Icons.music_note_rounded, size: 80, color: Colors.white.withOpacity(0.15)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white24,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
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
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
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
                          child: Text('Muat Ulang', style: TextStyle(color: theme.colorScheme.primary)),
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
    return InteractiveScaleButton(
      pressedScale: 0.95,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  width: 140, height: 140, fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 140, height: 140, color: Theme.of(context).colorScheme.surface,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 140, height: 140, color: Theme.of(context).colorScheme.surface,
                    child: Icon(Icons.music_note, color: Theme.of(context).dividerColor, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(item.title,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(item.author,
              style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 13),
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
    return InteractiveScaleButton(
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          image: DecorationImage(
            image: CachedNetworkImageProvider(item.thumbnailUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.8),
              ],
              stops: const [0.4, 0.7, 1.0],
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
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.author,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF2E2E2E) : Colors.grey[100]!;
    final placeholderColor = isDark ? Colors.white : Colors.black;
    final surfaceColor = isDark ? LumaColors.darkSurface : LumaColors.lightSurface;
    final textColor = isDark ? Colors.white : LumaColors.lightTextPrimary;

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: baseColor,
        highlightColor: highlightColor,
        duration: const Duration(milliseconds: 1200),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 160),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1 header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Baru saja didengar',
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            // Horizontal cards row
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(width: 140, height: 140, color: surfaceColor),
                      ),
                      const SizedBox(height: 12),
                      Container(height: 14, width: 100, color: placeholderColor),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 70, color: placeholderColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Section 3 – artist circles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Artis untukmu',
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 128,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (_, __) => Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
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