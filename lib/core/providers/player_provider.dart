import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/youtube_service.dart';

// --- Models ------------------------------------------------------------------

class PlayerState {
  final MusicItem? current;
  final List<MusicItem> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final bool isFavorite;
  final String? error;

  const PlayerState({
    this.current,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isFavorite = false,
    this.error,
  });

  PlayerState copyWith({
    MusicItem? current,
    List<MusicItem>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    bool? isFavorite,
    String? error,
  }) {
    return PlayerState(
      current: current ?? this.current,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isFavorite: isFavorite ?? this.isFavorite,
      error: error,
    );
  }

  bool get hasTrack => current != null;
}

// --- Notifier -----------------------------------------------------------------

class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _player = AudioPlayer();
  final YouTubeService _yt = YouTubeService();

  PlayerNotifier() : super(const PlayerState()) {
    _player.playingStream.listen((playing) {
      if (mounted) state = state.copyWith(isPlaying: playing);
    });
    _player.positionStream.listen((pos) {
      if (mounted) state = state.copyWith(position: pos);
    });
    _player.durationStream.listen((dur) {
      if (mounted && dur != null) state = state.copyWith(duration: dur);
    });
    _player.playerStateStream.listen((ps) {
      if (!mounted) return;
      if (ps.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  // -- Public API --------------------------------------------------------------

  Future<void> play(List<MusicItem> queue, int index) async {
    state = state.copyWith(
      queue: queue,
      currentIndex: index,
      current: queue[index],
      isLoading: true,
      error: null,
    );
    await _loadAndPlay(queue[index]);
    await _checkFavorite();
    await _saveRecentlyPlayed(queue[index]);
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration pos) => _player.seek(pos);

  Future<void> next() async {
    if (state.currentIndex < state.queue.length - 1) {
      final i = state.currentIndex + 1;
      state = state.copyWith(currentIndex: i, current: state.queue[i], isLoading: true, error: null);
      await _loadAndPlay(state.queue[i]);
      await _checkFavorite();
      await _saveRecentlyPlayed(state.queue[i]);
    }
  }

  Future<void> previous() async {
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (state.currentIndex > 0) {
      final i = state.currentIndex - 1;
      state = state.copyWith(currentIndex: i, current: state.queue[i], isLoading: true, error: null);
      await _loadAndPlay(state.queue[i]);
      await _checkFavorite();
      await _saveRecentlyPlayed(state.queue[i]);
    }
  }

  Future<void> toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || state.current == null) return;

    try {
      if (state.isFavorite) {
        await Supabase.instance.client
            .from('liked_songs')
            .delete()
            .eq('user_id', user.id)
            .eq('youtube_id', state.current!.id);
        if (mounted) state = state.copyWith(isFavorite: false);
      } else {
        await Supabase.instance.client.from('liked_songs').upsert({
          'user_id': user.id,
          'youtube_id': state.current!.id,
          'title': state.current!.title,
          'author': state.current!.author,
          'thumbnail': state.current!.thumbnailUrl,
        });
        if (mounted) state = state.copyWith(isFavorite: true);
      }
    } catch (e) {
      debugPrint('[Player] toggleFavorite error: $e');
    }
  }

  // -- Private -----------------------------------------------------------------

  Future<void> _loadAndPlay(MusicItem item) async {
    try {
      await _player.stop();
      final source = await _yt.getAudioSource(item);
      if (source == null) throw Exception('Tidak dapat memuat audio');
      await _player.setAudioSource(source);
      await _player.play();
      if (mounted) state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _playNext() async {
    if (state.currentIndex < state.queue.length - 1) {
      await next();
    }
  }

  Future<void> _checkFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || state.current == null) return;
    try {
      final data = await Supabase.instance.client
          .from('liked_songs')
          .select('id')
          .eq('user_id', user.id)
          .eq('youtube_id', state.current!.id)
          .maybeSingle();
      if (mounted) state = state.copyWith(isFavorite: data != null);
    } catch (_) {}
  }

  Future<void> _saveRecentlyPlayed(MusicItem item) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // Hapus duplikat dulu
      await Supabase.instance.client
          .from('recently_played')
          .delete()
          .eq('user_id', user.id)
          .eq('youtube_id', item.id);
      // Insert baru
      await Supabase.instance.client.from('recently_played').insert({
        'user_id': user.id,
        'youtube_id': item.id,
        'title': item.title,
        'author': item.author,
        'thumbnail': item.thumbnailUrl,
      });
    } catch (e) {
      debugPrint('[Player] saveRecentlyPlayed error: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _yt.dispose();
    super.dispose();
  }
}

// --- Provider -----------------------------------------------------------------

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(),
);
