import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../search/presentation/screens/artist_screen.dart';

// Design Read: Home feed for music app, ENERGY 2 / RHYTHM 2 / MOTION 1
// Greeting dynamically reflects time-of-day. Accent used only on filter chip (focal point).
// R-27: loading, empty, error states defined. R-03: bottom padding for mini player.
// R-29: darkBg base, darkSurface for cards, accent for one active chip.

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
  bool _loading = true;
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

      if (mounted) {
        final recent = (recentRes as List)
            .map((e) => MusicItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        final liked = (likedRes as List)
            .map((e) => MusicItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();

        // Light discovery: unique artists from library activity
        final seen = <String>{};
        final artists = <String>[];
        for (final t in [...recent, ...liked]) {
          final name = t.author.trim();
          if (name.isEmpty) continue;
          final key = name.toLowerCase();
          if (seen.contains(key)) continue;
          seen.add(key);
          artists.add(name);
          if (artists.length >= 12) break;
        }

        setState(() {
          _recentlyPlayed = recent;
          _likedSongs = liked;
          _artists = artists;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen error: $e');
      if (mounted) setState(() { _loading = false; _error = 'Gagal memuat data.'; });
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
                  // Avatar — navigate to profile
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: LumaColors.darkSurface,
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
    // R-27: loading state
    if (_loading) return const Center(child: CircularProgressIndicator(color: LumaColors.accent, strokeWidth: 2));

    // R-27: error state
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 48),
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
        // R-03: bottom padding for mini player + bottom nav bar
        padding: const EdgeInsets.only(bottom: 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // R-27: empty state — tell user what to do, not just "no data"
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

            // Recently played grid — only when data exists
            if (_recentlyPlayed.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _recentlyPlayed.length > 6 ? 6 : _recentlyPlayed.length,
                  itemBuilder: (context, i) => _GridCard(_recentlyPlayed[i], onTap: () {
                    ref.read(playerProvider.notifier).play(_recentlyPlayed, i);
                  }),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Recently played horizontal list
            if (_recentlyPlayed.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('Baru saja didengar',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              ),
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
              const SizedBox(height: 32),
            ],

            // Liked songs horizontal list — separate section with distinct heading
            if (_likedSongs.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
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
              const SizedBox(height: 32),
            ],

            // Artists from your activity
            if (_artists.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('Artis untukmu',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              ),
              SizedBox(
                height: 120,
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
        ),
      ),
    );
  }
}

// Grid card — Spotify "recently played" 2-col grid style
// R-31: darkSurface bg intentional for slight contrast vs. darkBg, radius 4 for consistency
class _GridCard extends StatelessWidget {
  const _GridCard(this.item, {required this.onTap});
  final MusicItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: LumaColors.darkSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Image.network(
              item.thumbnailUrl,
              width: 52, height: 52, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52, height: 52, color: const Color(0xFF222222),
                child: const Icon(Icons.music_note, color: Colors.white24, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              item.title,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// Horizontal card — album art + title + artist
// R-03: 120dp width stays within any phone without overflow
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
