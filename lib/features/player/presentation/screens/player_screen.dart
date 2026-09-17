import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/widgets/animated_heart_button.dart';
import '../../../../core/widgets/interactive_scale_button.dart';
import '../../../search/presentation/screens/artist_screen.dart';
import '../../../search/presentation/widgets/playlist_picker_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/lyrics_sheet.dart';
import '../widgets/queue_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Palette state provider: per-thumbnail URL
final _paletteProvider = FutureProvider.family<Color, String>((ref, url) async {
  if (url.isEmpty) return LumaColors.darkSurface;
  try {
    final pg = await PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(url),
      size: const Size(100, 100),
      maximumColorCount: 8,
    );
    final picked = pg.darkMutedColor?.color ??
        pg.darkVibrantColor?.color ??
        pg.dominantColor?.color;
    if (picked == null) return const Color(0xFF1A1A1A);
    final hsl = HSLColor.fromColor(picked);
    return hsl.withLightness(hsl.lightness.clamp(0.08, 0.28)).toColor();
  } catch (_) {
    return const Color(0xFF1A1A1A);
  }
});

class _DownloadBtn extends ConsumerWidget {
  const _DownloadBtn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    if (state.current == null) return const SizedBox.shrink();

    final item = state.current!;
    final isCached = state.isCached;
    final isDownloading = state.isDownloading;
    final progress = state.downloadingProgress;

    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: isDownloading
            ? CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
                value: progress?.clamp(0.0, 1.0),
              )
            : Icon(
                isCached ? Icons.download_done_rounded : Icons.download_rounded,
                color: isCached ? Colors.white : Colors.white60,
                size: 26,
              ),
        onPressed: () async {
          if (isCached) {
            ScaffoldMessenger.of(context).showSnackBar(
              _modernSnack('Lagu sudah tersimpan offline', isError: false),
            );
            return;
          }
          if (isDownloading) return;
          ScaffoldMessenger.of(context).showSnackBar(
            _modernSnack('Mengunduh…',
                isError: false, duration: const Duration(seconds: 2)),
          );
          await ref.read(playerProvider.notifier).downloadCurrent();
          final nowCached =
              await OfflineCacheService.instance.isCached(item.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            _modernSnack(
              nowCached ? 'Berhasil diunduh' : 'Gagal mengunduh',
              isError: !nowCached,
            ),
          );
        },
        tooltip: isCached ? 'Hapus unduhan' : 'Unduh untuk offline',
      ),
    );
  }
}

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  IconData _repeatIcon(RepeatMode mode) => switch (mode) {
        RepeatMode.off => Icons.repeat_rounded,
        RepeatMode.all => Icons.repeat_rounded,
        RepeatMode.one => Icons.repeat_one_rounded,
      };

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => const QueueSheet(),
    );
  }

  void _showLyrics(BuildContext context, String title, String artist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => LyricsSheet(title: title, artist: artist),
    );
  }

  void _showMore(BuildContext context, WidgetRef ref, PlayerState state) {
    final item = state.current!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                state.isCached
                    ? Icons.download_done_rounded
                    : Icons.download_rounded,
                color: Colors.white70,
              ),
              title: Text(
                state.isCached
                    ? 'Sudah tersimpan offline'
                    : 'Unduh untuk offline',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                if (state.isCached) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      _modernSnack('Lagu sudah ada di unduhan', isError: false),
                    );
                  }
                  return;
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _modernSnack('Mengunduh…',
                        isError: false, duration: const Duration(seconds: 2)),
                  );
                }
                final ok =
                    await ref.read(playerProvider.notifier).downloadCurrent();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  _modernSnack(
                    ok ? 'Berhasil diunduh' : 'Gagal mengunduh lagu',
                    isError: !ok,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded,
                  color: Colors.white70),
              title: Text('Lihat ${item.author}',
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ArtistScreen(artistName: item.author)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.lyrics_outlined, color: Colors.white70),
              title: const Text('Lirik',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                _showLyrics(context, item.title, item.author);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final onSurface = theme.colorScheme.onSurface;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    // Listen to changes EXCEPT position to avoid rebuilds every 200ms
    ref.watch(playerProvider.select((s) => (
          s.current,
          s.isShuffled,
          s.repeatMode,
          s.isPlaying,
          s.isFavorite,
          s.isLoading,
          s.loadingStatus,
          s.queue,
        )));

    // Get the full state snapshot for this build
    final state = ref.read(playerProvider);

    if (state.current == null) {
      return Scaffold(backgroundColor: scaffoldBg);
    }

    final item = state.current!;
    final shuffleActive = state.isShuffled;
    final repeatActive = state.repeatMode != RepeatMode.off;

    final paletteAsync = ref.watch(_paletteProvider(item.thumbnailUrl));
    final bgColor = paletteAsync.maybeWhen(
      data: (c) => c,
      orElse: () => theme.brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFE0E0E0),
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          final vy = details.primaryVelocity ?? 0;
          if (vy > 280) {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bgColor.withOpacity(0.8),
                Color.lerp(bgColor, scaffoldBg, 0.6) ?? scaffoldBg,
                scaffoldBg,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── AppBar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: onSurface, size: 32),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Tutup',
                      ),
                      Expanded(
                        child: Text(
                          'Sedang diputar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onSurface.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert_rounded,
                            color: onSurface, size: 24),
                        onPressed: () => _showMore(context, ref, state),
                        tooltip: 'Opsi lainnya',
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Artwork with Breathing Vinyl scale & ambient glow ─────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedScale(
                    scale: state.isPlaying ? 1.0 : 0.91,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: state.isPlaying
                                  ? bgColor.withValues(alpha: 0.55)
                                  : Colors.black.withValues(alpha: 0.25),
                              blurRadius: state.isPlaying ? 36 : 16,
                              offset: Offset(0, state.isPlaying ? 14 : 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'player_artwork_${item.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item.thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF1A1A1A),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Icon(Icons.music_note_rounded,
                                    color: Colors.white24, size: 64),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Track info + Download + Like ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ArtistScreen(artistName: item.author)),
                              ),
                              child: Text(
                                item.author,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.playlist_add_rounded),
                        color: onSurface.withValues(alpha: 0.8),
                        iconSize: 26,
                        tooltip: 'Tambah ke Playlist',
                        onPressed: () {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => PlaylistPickerSheet(
                                item: item,
                                userId: user.id,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan login untuk menambah ke playlist'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      const _DownloadBtn(),
                      const SizedBox(width: 4),
                      // Animated Bouncy Like
                      AnimatedHeartButton(
                        isLiked: state.isFavorite,
                        size: 26,
                        activeColor: const Color(0xFFEF4444),
                        inactiveColor: onSurface.withValues(alpha: 0.6),
                        onTap: () async {
                          try {
                            final res = await ref
                                .read(playerProvider.notifier)
                                .toggleFavorite();
                            if (context.mounted && res != null) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        res ? Icons.favorite_rounded : Icons.heart_broken_rounded,
                                        color: res ? const Color(0xFFEF4444) : Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        res
                                            ? 'Ditambahkan ke Lagu yang Disukai'
                                            : 'Dihapus dari Lagu yang Disukai',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            } else if (context.mounted && res == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Silakan login untuk menyukai lagu'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal memperbarui status favorit: $e'),
                                  backgroundColor: Colors.red.shade900,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Progress slider ────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _PositionSlider(),
                ),

                const SizedBox(height: 12),

                // -- Playback controls (5 primary actions with spacious touch targets) --
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shuffle
                      _ControlBtn(
                        icon: Icons.shuffle_rounded,
                        size: 24,
                        color: shuffleActive ? onSurface : onSurface.withOpacity(0.38),
                        onTap: () =>
                            ref.read(playerProvider.notifier).toggleShuffle(),
                        badge: shuffleActive,
                      ),
                      // Skip Previous
                      _ControlBtn(
                        icon: Icons.skip_previous_rounded,
                        size: 38,
                        color: onSurface,
                        onTap: () =>
                            ref.read(playerProvider.notifier).previous(),
                      ),
                      // Play/Pause (Central Hero focal point with spring bounce)
                      InteractiveScaleButton(
                        pressedScale: 0.88,
                        onTap: () =>
                            ref.read(playerProvider.notifier).togglePlayPause(),
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: onSurface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: onSurface.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: state.isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: scaffoldBg,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Icon(
                                    state.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: scaffoldBg,
                                    size: 40,
                                  ),
                          ),
                        ),
                      ),
                      // Skip Next
                      _ControlBtn(
                        icon: Icons.skip_next_rounded,
                        size: 38,
                        color: onSurface,
                        onTap: () => ref.read(playerProvider.notifier).next(),
                      ),
                      // Repeat
                      _ControlBtn(
                        icon: _repeatIcon(state.repeatMode),
                        size: 24,
                        color: repeatActive ? onSurface : onSurface.withOpacity(0.38),
                        onTap: () =>
                            ref.read(playerProvider.notifier).cycleRepeat(),
                        badge: repeatActive,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Secondary Actions (Lirik, Antrean) ───────────────────────
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SecondaryBtn(
                        icon: Icons.lyrics_outlined,
                        label: 'Lirik',
                        onTap: () =>
                            _showLyrics(context, item.title, item.author),
                      ),
                      _SecondaryBtn(
                        icon: Icons.queue_music_rounded,
                        label: 'Antrean (${state.queue.length})',
                        onTap: () => _showQueue(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

SnackBar _modernSnack(String msg, {Duration? duration, bool isError = false}) {
  return SnackBar(
    content: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
          color: isError ? Colors.red.shade300 : Colors.white,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    ),
    backgroundColor: LumaColors.darkSurface,
    behavior: SnackBarBehavior.floating,
    duration: duration ?? const Duration(seconds: 3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

/// Compact icon button with guaranteed 48×48 touch target and spring bounce.
class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return InteractiveScaleButton(
      pressedScale: 0.86,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: size),
            if (badge)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _PositionSlider extends ConsumerWidget {
  const _PositionSlider();

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    final duration = ref.watch(playerProvider.select((s) => s.duration));
    final position = ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final loadingStatus = ref.watch(playerProvider.select((s) => s.loadingStatus));

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: onSurface,
            inactiveTrackColor: onSurface.withOpacity(0.24),
            thumbColor: onSurface,
            overlayColor: onSurface.withOpacity(0.12),
          ),
          child: Slider(
            min: 0.0,
            max: duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
            value: position.inMilliseconds.toDouble().clamp(
                  0.0,
                  duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                ),
            onChanged: (val) => ref
                .read(playerProvider.notifier)
                .seekTo(Duration(milliseconds: val.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_fmt(position),
                      style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.replay_10_rounded, size: 20, color: onSurface.withOpacity(0.7)),
                    onPressed: () => ref
                        .read(playerProvider.notifier)
                        .seekBackward(const Duration(seconds: 10)),
                    tooltip: 'Mundur 10 detik',
                  ),
                ],
              ),
              if (isLoading && loadingStatus != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      loadingStatus,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: onSurface.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              if (!(isLoading && loadingStatus != null))
                const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.forward_10_rounded, size: 20, color: onSurface.withOpacity(0.7)),
                    onPressed: () => ref
                        .read(playerProvider.notifier)
                        .seekForward(const Duration(seconds: 10)),
                    tooltip: 'Maju 10 detik',
                  ),
                  const SizedBox(width: 8),
                  Text(_fmt(duration),
                      style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
