import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../search/presentation/screens/artist_screen.dart';
import '../widgets/lyrics_sheet.dart';
import '../widgets/queue_sheet.dart';

// Palette state provider — per-thumbnail URL
final _paletteProvider =
    FutureProvider.family<Color, String>((ref, url) async {
  if (url.isEmpty) return LumaColors.darkSurface;
  try {
    final pg = await PaletteGenerator.fromImageProvider(
      NetworkImage(url),
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
                color: LumaColors.accent,
                value: progress != null ? progress.clamp(0.0, 1.0) : null,
              )
            : Icon(
                isCached ? Icons.download_done_rounded : Icons.download_rounded,
                color: isCached ? LumaColors.accent : Colors.white,
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
            _modernSnack('Mengunduh…', isError: false, duration: const Duration(seconds: 2)),
          );
          await ref.read(playerProvider.notifier).downloadCurrent();
          if (!context.mounted) return;
          final nowCached = await OfflineCacheService.instance.isCached(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            _modernSnack(
              nowCached ? 'Berhasil diunduh 🎵' : 'Gagal mengunduh',
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

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

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
                state.isCached ? 'Sudah tersimpan offline' : 'Unduh untuk offline',
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
                    _modernSnack('Mengunduh…', isError: false, duration: const Duration(seconds: 2)),
                  );
                }
                final ok = await ref.read(playerProvider.notifier).downloadCurrent();
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
              leading: const Icon(Icons.person_outline_rounded, color: Colors.white70),
              title: Text('Lihat ${item.author}',
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ArtistScreen(artistName: item.author)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.lyrics_outlined, color: Colors.white70),
              title: const Text('Lirik', style: TextStyle(color: Colors.white, fontSize: 15)),
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
    final state = ref.watch(playerProvider);
    if (state.current == null) {
      return const Scaffold(backgroundColor: LumaColors.darkBg);
    }

    final item = state.current!;
    final shuffleActive = state.isShuffled;
    final repeatActive = state.repeatMode != RepeatMode.off;

    final paletteAsync = ref.watch(_paletteProvider(item.thumbnailUrl));
    final bgColor = paletteAsync.maybeWhen(
      data: (c) => c,
      orElse: () => const Color(0xFF1A1A1A),
    );

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor, LumaColors.darkBg],
            stops: const [0.0, 0.55],
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
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                    const Expanded(
                      child: Text(
                        'Sedang diputar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white, size: 24),
                      onPressed: () => _showMore(context, ref, state),
                      tooltip: 'Opsi lainnya',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Artwork ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedScale(
                  scale: state.isPlaying ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: bgColor.withValues(alpha: 0.6),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
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
                            style: const TextStyle(
                              color: Colors.white,
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
                              style: const TextStyle(
                                color: LumaColors.darkTextSecondary,
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
                    const _DownloadBtn(),
                    const SizedBox(width: 4),
                    // 48×48 Like
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            state.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(state.isFavorite),
                            color: state.isFavorite
                                ? LumaColors.accent
                                : Colors.white,
                            size: 26,
                          ),
                        ),
                        onPressed: () =>
                            ref.read(playerProvider.notifier).toggleFavorite(),
                        tooltip: state.isFavorite
                            ? 'Hapus dari favorit'
                            : 'Tambah ke favorit',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Progress slider ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 18),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white12,
                      ),
                      child: Slider(
                        min: 0.0,
                        max: state.duration.inMilliseconds
                            .toDouble()
                            .clamp(1.0, double.infinity),
                        value: state.position.inMilliseconds
                            .toDouble()
                            .clamp(
                              0.0,
                              state.duration.inMilliseconds
                                  .toDouble()
                                  .clamp(1.0, double.infinity),
                            ),
                        onChanged: (val) => ref
                            .read(playerProvider.notifier)
                            .seekTo(Duration(milliseconds: val.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(state.position),
                              style: const TextStyle(
                                  color: LumaColors.darkTextSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                          if (state.isLoading && state.loadingStatus != null)
                            Text(
                              state.loadingStatus!,
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          Text(_fmt(state.duration),
                              style: const TextStyle(
                                  color: LumaColors.darkTextSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Playback controls ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shuffle
                    _ControlBtn(
                      icon: Icons.shuffle_rounded,
                      size: 22,
                      color: shuffleActive ? LumaColors.accent : Colors.white70,
                      onTap: () =>
                          ref.read(playerProvider.notifier).toggleShuffle(),
                      badge: shuffleActive,
                    ),
                    // Skip Previous
                    _ControlBtn(
                      icon: Icons.skip_previous_rounded,
                      size: 36,
                      color: Colors.white,
                      onTap: () =>
                          ref.read(playerProvider.notifier).previous(),
                    ),
                    // Skip Backward 10s
                    _ControlBtn(
                      icon: Icons.replay_10_rounded,
                      size: 24,
                      color: Colors.white54,
                      onTap: () =>
                          ref.read(playerProvider.notifier).seekBackward(const Duration(seconds: 10)),
                    ),
                    // Play/Pause
                    GestureDetector(
                      onTap: () =>
                          ref.read(playerProvider.notifier).togglePlayPause(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Icon(
                                  state.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 38,
                                ),
                        ),
                      ),
                    ),
                    // Skip Forward 10s
                    _ControlBtn(
                      icon: Icons.forward_10_rounded,
                      size: 24,
                      color: Colors.white54,
                      onTap: () =>
                          ref.read(playerProvider.notifier).seekForward(const Duration(seconds: 10)),
                    ),
                    // Skip Next
                    _ControlBtn(
                      icon: Icons.skip_next_rounded,
                      size: 36,
                      color: Colors.white,
                      onTap: () => ref.read(playerProvider.notifier).next(),
                    ),
                    // Repeat
                    _ControlBtn(
                      icon: _repeatIcon(state.repeatMode),
                      size: 22,
                      color: repeatActive ? LumaColors.accent : Colors.white70,
                      onTap: () =>
                          ref.read(playerProvider.notifier).cycleRepeat(),
                      badge: repeatActive,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Secondary actions ──────────────────────────────────────
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
                      label: 'Antrian (${state.queue.length})',
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
          color: isError ? Colors.red.shade300 : LumaColors.accent,
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

/// Compact icon button with guaranteed 48×48 touch target.
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
                  decoration: BoxDecoration(
                    color: LumaColors.accent,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}