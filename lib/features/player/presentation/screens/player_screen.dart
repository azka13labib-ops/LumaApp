import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final List<MusicItem> playlist;
  final int initialIndex;

  const PlayerScreen({super.key, required this.playlist, required this.initialIndex});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  final YouTubeService _yt = YouTubeService();
  bool _loading = true;
  String? _error;
  late int _idx;
  late MusicItem _current;
  
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _current = widget.playlist[_idx];
    _initAudio();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final data = await Supabase.instance.client
          .from('liked_songs')
          .select('id')
          .eq('user_id', user.id)
          .eq('youtube_id', _current.id)
          .maybeSingle();
          
      if (mounted) setState(() => _isFavorite = data != null);
    } catch (_) {
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login untuk menyimpan favorit')));
        return;
      }

      if (_isFavorite) {
        await Supabase.instance.client
            .from('liked_songs')
            .delete()
            .eq('user_id', user.id)
            .eq('youtube_id', _current.id);
        if (mounted) setState(() => _isFavorite = false);
      } else {
        await Supabase.instance.client
            .from('liked_songs')
            .insert({
              'user_id': user.id,
              'youtube_id': _current.id,
              'title': _current.title,
              'author': _current.author,
              'thumbnail_url': _current.thumbnailUrl,
            });
        if (mounted) setState(() => _isFavorite = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan favorit.')));
      }
    }
  }

  Future<void> _initAudio() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final src = await _yt.getAudioSource(_current);
      if (src == null) throw Exception('Sumber audio tidak ditemukan.');
      await _player.setAudioSource(src).timeout(const Duration(seconds: 15));
      _player.play();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memutar. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _player.dispose(); _yt.dispose(); super.dispose(); }

  void _next()     { if (_idx < widget.playlist.length - 1) { _idx++; _current = widget.playlist[_idx]; _initAudio(); _checkFavorite(); } }
  void _previous() { if (_idx > 0) { _idx--; _current = widget.playlist[_idx]; _initAudio(); _checkFavorite(); } }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? LumaColors.darkBg : LumaColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('Sedang Diputar', style: tt.labelSmall),
            const SizedBox(height: 2),
            Text(_current.author, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── Album Art ── focal point, hard box-shadow (no ambient glow)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _current.thumbnailUrl,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width - 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width - 48,
                      color: isDark ? LumaColors.darkSurface : LumaColors.lightSurface,
                      child: Icon(Icons.music_note, size: 64, color: cs.primary),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Title & Artist
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_current.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.headlineMedium?.copyWith(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(_current.author, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.redAccent : cs.onSurface.withValues(alpha: 0.35),
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Seek Bar
              if (!_loading && _error == null) _buildSeekBar(cs),

              const SizedBox(height: 20),

              // ── Controls
              _buildControls(cs),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(ColorScheme cs) {
    if (_loading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
          const SizedBox(height: 12),
          Text('Menyiapkan audio...', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: _initAudio, child: const Text('Coba Lagi')),
        ],
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snap) {
        final playing = snap.data?.playing ?? false;
        final proc = snap.data?.processingState;
        final buffering = proc == ProcessingState.loading || proc == ProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous
            IconButton(
              iconSize: 36,
              icon: Icon(Icons.skip_previous_rounded,
                  color: _idx > 0 ? cs.onSurface : cs.onSurface.withValues(alpha: 0.25)),
              onPressed: _idx > 0 ? _previous : null,
            ),

            // Play / Pause — primary focal point, blue accent
            SizedBox(
              width: 64, height: 64,
              child: buffering
                  ? CircularProgressIndicator(color: cs.primary, strokeWidth: 2)
                  : IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: cs.primary),
                      iconSize: 32,
                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white),
                      onPressed: playing ? _player.pause : _player.play,
                    ),
            ),

            // Next
            IconButton(
              iconSize: 36,
              icon: Icon(Icons.skip_next_rounded,
                  color: _idx < widget.playlist.length - 1
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.25)),
              onPressed: _idx < widget.playlist.length - 1 ? _next : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeekBar(ColorScheme cs) {
    return StreamBuilder<Duration?>(
      stream: _player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = _player.duration ?? Duration.zero;
        final max = dur.inMilliseconds.toDouble();

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: pos.inMilliseconds.toDouble().clamp(0, max > 0 ? max : 1),
                min: 0,
                max: max > 0 ? max : 1,
                onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(pos), style: Theme.of(context).textTheme.labelSmall),
                  Text(_fmt(dur), style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
