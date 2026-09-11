import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/offline_cache_service.dart';
import '../services/settings_service.dart';
import '../services/youtube_service.dart';

enum RepeatMode { off, all, one }

class PlayerState {
  final MusicItem? current;
  final List<MusicItem> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final bool isFavorite;
  final bool isShuffled;
  final RepeatMode repeatMode;
  final bool isCached;
  final bool isDownloading;
  final double? downloadingProgress;
  final String? error;
  final String? loadingStatus; // e.g. "Mengambil audio…", "Menyiapkan pemutar…"

  const PlayerState({
    this.current,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isFavorite = false,
    this.isShuffled = false,
    this.repeatMode = RepeatMode.off,
    this.isCached = false,
    this.isDownloading = false,
    this.downloadingProgress,
    this.error,
    this.loadingStatus,
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
    bool? isShuffled,
    RepeatMode? repeatMode,
    bool? isCached,
    bool? isDownloading,
    double? downloadingProgress,
    String? error,
    String? loadingStatus,
    bool clearError = false,
    bool clearLoadingStatus = false,
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
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      isCached: isCached ?? this.isCached,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadingProgress: downloadingProgress ?? this.downloadingProgress,
      error: clearError ? null : (error ?? this.error),
      loadingStatus:
          clearLoadingStatus ? null : (loadingStatus ?? this.loadingStatus),
    );
  }

  bool get hasTrack => current != null;
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _player = AudioPlayer();
  final YouTubeService _yt = YouTubeService();
  final _rng = Random();

  /// Monotonically increasing counter. Each call to _loadAndPlay captures
  /// the current value; if a newer load starts before we finish, we abort
  /// the stale operation silently. Replaces a CancelToken.
  int _loadId = 0;

  /// Original order before shuffle (restored when shuffle turns off).
  List<MusicItem> _orderBackup = [];

  final Ref? _ref;

  PlayerNotifier([this._ref]) : super(const PlayerState()) {

    _player.playingStream.listen((playing) {
      if (mounted) {
        state = state.copyWith(
          isPlaying: playing,
          isLoading: playing ? false : state.isLoading,
          clearLoadingStatus: playing ? true : false,
        );
      }
    });
    // Swallow async playback errors — just_audio can otherwise surface an
    // unhandled platform exception that crashes the app mid-stick.
    _player.errorStream.listen((e) {
      debugPrint('[Player] just_audio errorStream: ${e.code} ${e.message}');
    });
    _player.positionStream.listen((pos) {
      if (mounted) state = state.copyWith(position: pos);
    });
    _player.durationStream.listen((dur) {
      if (mounted && dur != null) state = state.copyWith(duration: dur);
    });
    _player.playerStateStream.listen((ps) {
      if (!mounted) return;
      // Immediately cancel loading state as soon as player is ready or actively playing
      if (ps.playing || ps.processingState == ProcessingState.ready) {
        if (state.isLoading) {
          state = state.copyWith(isLoading: false, clearLoadingStatus: true);
        }
      }
      // When the track finishes, trigger next
      if (ps.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  // -- Public API --------------------------------------------------------------

  Future<void> play(List<MusicItem> queue, int index) async {
    if (queue.isEmpty || index < 0 || index >= queue.length) return;
    _orderBackup = List<MusicItem>.from(queue);
    state = state.copyWith(
      queue: queue,
      currentIndex: index,
      current: queue[index],
      isLoading: true,
      isShuffled: false,
      clearError: true,
      loadingStatus: 'Mengambil audio…',
    );
    await _loadAndPlay(queue[index]);
    _checkFavorite().catchError((e) => debugPrint('[Player] checkFavorite: $e'));
    _saveRecentlyPlayed(queue[index])
        .catchError((e) => debugPrint('[Player] saveRecent: $e'));
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _player.pause();
    } else {
      state = state.copyWith(isLoading: false);
      unawaited(_player.play());
    }
  }

  Future<void> seekTo(Duration pos) => _player.seek(pos);

  Future<void> seekBackward(Duration sec) => seekTo(state.position - sec);
  Future<void> seekForward(Duration sec) => seekTo(state.position + sec);


  Future<void> next() async {
    if (state.queue.isEmpty) return;

    if (state.currentIndex < state.queue.length - 1) {
      await _playAt(state.currentIndex + 1);
    } else if (state.repeatMode == RepeatMode.all) {
      await _playAt(0);
    } else {
      final autoplay = _ref?.read(settingsProvider).autoplay ?? true;
      if (autoplay) {
        await _autoplayFromLibrary();
      }
    }
  }

  Future<void> previous() async {
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (state.currentIndex > 0) {
      await _playAt(state.currentIndex - 1);
    } else if (state.repeatMode == RepeatMode.all && state.queue.isNotEmpty) {
      await _playAt(state.queue.length - 1);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    if (state.queue.isEmpty || state.current == null) return;

    if (state.isShuffled) {
      final currentId = state.current!.id;
      final restored = _orderBackup.isNotEmpty
          ? List<MusicItem>.from(_orderBackup)
          : List<MusicItem>.from(state.queue);
      var idx = restored.indexWhere((t) => t.id == currentId);
      if (idx < 0) idx = 0;
      state = state.copyWith(queue: restored, currentIndex: idx, isShuffled: false);
    } else {
      _orderBackup = List<MusicItem>.from(state.queue);
      final current = state.current!;
      final rest = state.queue.where((t) => t.id != current.id).toList()..shuffle(_rng);
      final shuffled = [current, ...rest];
      state = state.copyWith(queue: shuffled, currentIndex: 0, isShuffled: true);
    }
  }

  void cycleRepeat() {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: next);
  }


  void addToQueue(MusicItem item) {
    if (state.queue.isEmpty) {
      play([item], 0);
      return;
    }
    final q = List<MusicItem>.from(state.queue)..add(item);
    if (!state.isShuffled) {
      _orderBackup = List<MusicItem>.from(q);
    }
    state = state.copyWith(queue: q);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    if (index == state.currentIndex) return;

    final q = List<MusicItem>.from(state.queue)..removeAt(index);
    var newIndex = state.currentIndex;
    if (index < state.currentIndex) newIndex -= 1;
    if (!state.isShuffled) {
      _orderBackup = List<MusicItem>.from(q);
    }
    state = state.copyWith(queue: q, currentIndex: newIndex);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= state.queue.length) return;
    if (newIndex < 0 || newIndex >= state.queue.length) return;

    final q = List<MusicItem>.from(state.queue);
    final item = q.removeAt(oldIndex);
    q.insert(newIndex, item);

    final currentId = state.current?.id;
    var newCurrent = q.indexWhere((t) => t.id == currentId);
    if (newCurrent < 0) newCurrent = 0;

    if (!state.isShuffled) {
      _orderBackup = List<MusicItem>.from(q);
    }
    state = state.copyWith(queue: q, currentIndex: newCurrent);
  }

  Future<void> jumpToQueueIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    if (index == state.currentIndex) return;
    await _playAt(index);
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
          'artist': state.current!.author,
          'cover_url': state.current!.thumbnailUrl,
        });
        if (mounted) state = state.copyWith(isFavorite: true);
      }
    } catch (e) {
      debugPrint('[Player] toggleFavorite error: $e');
    }
  }

  Future<bool> downloadCurrent() async {
    final item = state.current;
    if (item == null) return false;
    try {
      if (await OfflineCacheService.instance.isCached(item.id)) {
        state = state.copyWith(isCached: true, isDownloading: false);
        return true;
      }
      state = state.copyWith(isDownloading: true, downloadingProgress: 0.0);
      final url = await _yt.resolveStreamUrl(item);
      if (url == null) {
        state = state.copyWith(isDownloading: false, downloadingProgress: null);
        return false;
      }
      OfflineCacheService.instance.downloadProgress.addListener(_onDownloadProgress);
      await OfflineCacheService.instance.download(item, url);
      OfflineCacheService.instance.downloadProgress.removeListener(_onDownloadProgress);
      if (mounted) {
        state = state.copyWith(isCached: true, isDownloading: false, downloadingProgress: null);
      }
      return true;
    } catch (e) {
      debugPrint('[Player] download error: $e');
      state = state.copyWith(isDownloading: false, downloadingProgress: null);
      return false;
    }
  }

  void _onDownloadProgress() {
    final progress = OfflineCacheService.instance.getProgress(state.current?.id ?? '');
    if (mounted && progress != null) {
      state = state.copyWith(isDownloading: true, downloadingProgress: progress);
    }
  }

  Future<bool> downloadTrack(MusicItem item) async {
    try {
      if (await OfflineCacheService.instance.isCached(item.id)) return true;
      state = state.copyWith(isDownloading: true, downloadingProgress: 0.0);
      final url = await _yt.resolveStreamUrl(item);
      if (url == null) {
        state = state.copyWith(isDownloading: false, downloadingProgress: null);
        return false;
      }
      OfflineCacheService.instance.downloadProgress.addListener(_onDownloadProgress);
      await OfflineCacheService.instance.download(item, url);
      OfflineCacheService.instance.downloadProgress.removeListener(_onDownloadProgress);
      if (mounted && state.current?.id == item.id) {
        state = state.copyWith(isCached: true, isDownloading: false, downloadingProgress: null);
      }
      return true;
    } catch (e) {
      debugPrint('[Player] downloadTrack error: $e');
      state = state.copyWith(isDownloading: false, downloadingProgress: null);
      return false;
    }
  }

  // -- Private -----------------------------------------------------------------

  Future<void> _playAt(int index) async {
    state = state.copyWith(
      currentIndex: index,
      current: state.queue[index],
      isLoading: true,
      clearError: true,
      loadingStatus: 'Mengambil audio…',
    );
    await _loadAndPlay(state.queue[index]);
    _checkFavorite().catchError((e) => debugPrint('[Player] checkFavorite: $e'));
    _saveRecentlyPlayed(state.queue[index])
        .catchError((e) => debugPrint('[Player] saveRecent: $e'));
  }

  Future<void> _loadAndPlay(MusicItem item) async {
    // Capture this load's token. Any subsequent call increments _loadId,
    // making this one stale — we check and bail out before touching the player.
    final myId = ++_loadId;

    try {
      // Resolve the audio source BEFORE touching the player. Stopping the
      // player first and then waiting 20-120s for youtube-mp36 leaves just_audio
      // with a null currentIndex — just_audio_background broadcasts the media
      // session state during that window and can crash on some ROMs. Keeping
      // the previous source loaded (or idle/loaded) until the swap avoids it.
      final cached = await OfflineCacheService.instance.isCached(item.id);
      final offlineOnly = _ref?.read(settingsProvider).offlineOnly ?? false;

      if (offlineOnly && !cached) {
        throw Exception('Mode Hanya Offline aktif: lagu ini belum tersimpan di perangkat.');
      }

      if (!mounted || myId != _loadId) return;

      if (mounted) {
        state = state.copyWith(loadingStatus: 'Menyiapkan pemutar…');
      }

      final quality =
          _ref?.read(settingsProvider).audioQuality ?? AudioQuality.auto;
      final realSource = await _yt.getAudioSource(item, quality: quality);

      if (!mounted || myId != _loadId) return;

      if (realSource == null) throw Exception('Tidak dapat memuat audio');

      // Set real audio source directly without remote dummy dependencies
      await _player.setAudioSource(realSource);

      if (!mounted || myId != _loadId) return;

      // Reset loading state right as playback begins so play button updates immediately
      if (mounted && myId == _loadId) {
        state = state.copyWith(
          isLoading: false,
          isCached: cached,
          isDownloading: false,
          downloadingProgress: null,
          clearError: true,
          clearLoadingStatus: true,
        );
      }

      // Do NOT await _player.play(): in just_audio, play() completes only when
      // playback pauses or finishes. Awaiting it would freeze execution here while playing.
      unawaited(_player.play());
    } catch (e) {
      final isInterrupt = e.toString().contains('Loading interrupted') ||
          e.toString().contains('interrupted');

      if (!mounted) return;
      if (myId != _loadId) return;

      if (isInterrupt) {
        return;
      }

      debugPrint('[Player] _loadAndPlay error: $e');
      state = state.copyWith(
        isLoading: false,
        isDownloading: false,
        downloadingProgress: null,
        clearLoadingStatus: true,
        error: 'Gagal memutar audio: $e',
      );
    }
  }

  Future<void> _onTrackCompleted() async {
    if (state.repeatMode == RepeatMode.one) {
      await _player.seek(Duration.zero);
      unawaited(_player.play());
      return;
    }
    await next();
  }

  /// When queue ends: pick a random liked / recent track.
  Future<void> _autoplayFromLibrary() async {
    final user = Supabase.instance.client.auth.currentUser;
    final pool = <MusicItem>[];

    try {
      final offline = await OfflineCacheService.instance.listCached();
      pool.addAll(offline);

      if (user != null) {
        final liked = await Supabase.instance.client
            .from('liked_songs')
            .select()
            .eq('user_id', user.id)
            .limit(40);
        for (final e in liked as List) {
          pool.add(MusicItem.fromMap(Map<String, dynamic>.from(e as Map)));
        }

        final recent = await Supabase.instance.client
            .from('recently_played')
            .select()
            .eq('user_id', user.id)
            .order('played_at', ascending: false)
            .limit(20);
        for (final e in recent as List) {
          pool.add(MusicItem.fromMap(Map<String, dynamic>.from(e as Map)));
        }
      }
    } catch (e) {
      debugPrint('[Player] autoplay pool error: $e');
    }

    final seen = <String>{};
    final currentId = state.current?.id;
    final candidates = <MusicItem>[];
    for (final t in pool) {
      if (t.id.isEmpty || t.id == currentId || !seen.add(t.id)) continue;
      candidates.add(t);
    }

    if (candidates.isEmpty) {
      debugPrint('[Player] autoplay: no library tracks');
      return;
    }

    final pick = candidates[_rng.nextInt(candidates.length)];
    debugPrint('[Player] autoplay → ${pick.title}');
    await play([...state.queue, pick], state.queue.length);
  }

  Future<void> _checkFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || state.current == null) return;
    try {
      final data = await Supabase.instance.client
          .from('liked_songs')
          .select('youtube_id')
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
      // Single upsert on (user_id, youtube_id) — no double round-trip
      await Supabase.instance.client.from('recently_played').upsert({
        'user_id': user.id,
        'youtube_id': item.id,
        'title': item.title,
        'artist': item.author,
        'cover_url': item.thumbnailUrl,
        'played_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,youtube_id');
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

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(ref),
);
