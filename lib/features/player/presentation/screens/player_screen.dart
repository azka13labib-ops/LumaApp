import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/player_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    if (state.current == null) return const Scaffold(backgroundColor: LumaColors.darkBg);

    final item = state.current!;

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Memutar dari playlist', style: TextStyle(color: Colors.white, fontSize: 12)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              LumaColors.accent.withValues(alpha: 0.3),
              LumaColors.darkBg,
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Artwork
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title & Favorite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.author,
                          style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      state.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: state.isFavorite ? LumaColors.accent : Colors.white,
                      size: 28,
                    ),
                    onPressed: () => ref.read(playerProvider.notifier).toggleFavorite(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Progress Bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  min: 0.0,
                  max: state.duration.inMilliseconds.toDouble(),
                  value: state.position.inMilliseconds.toDouble().clamp(0.0, state.duration.inMilliseconds.toDouble()),
                  onChanged: (val) {
                    ref.read(playerProvider.notifier).seekTo(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(state.position), style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12)),
                    Text(_formatDuration(state.duration), style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.shuffle, color: Colors.white), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                    onPressed: () => ref.read(playerProvider.notifier).previous(),
                  ),
                  Container(
                    decoration: const BoxDecoration(color: LumaColors.accent, shape: BoxShape.circle),
                    child: IconButton(
                      icon: state.isLoading
                          ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Icon(state.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
                      padding: const EdgeInsets.all(16),
                      onPressed: () => ref.read(playerProvider.notifier).togglePlayPause(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                    onPressed: () => ref.read(playerProvider.notifier).next(),
                  ),
                  IconButton(icon: const Icon(Icons.repeat, color: Colors.white), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
