import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/services/youtube_service.dart';

class PlayerScreen extends StatefulWidget {
  final MusicItem musicItem;

  const PlayerScreen({
    super.key,
    required this.musicItem,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YouTubeService _ytService = YouTubeService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final audioSource = await _ytService.getAudioSource(widget.musicItem);
      if (audioSource != null) {
        await _audioPlayer.setAudioSource(audioSource);
        _audioPlayer.play();
      } else {
        throw Exception('Gagal mendapatkan sumber audio.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal memutar audio: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _ytService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sedang Diputar', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Art dengan bayangan subtle (Antislop R-12/13)
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB8FF22).withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.musicItem.thumbnailUrl,
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.width - 48,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Title and Author
              Text(
                widget.musicItem.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                widget.musicItem.author,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 48),

              // Player Controls
              _buildPlayerControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerControls() {
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: Color(0xFFB8FF22)),
          SizedBox(height: 16),
          Text(
            'Mengunduh audio...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Gagal memutar audio.',
          style: TextStyle(color: Colors.redAccent),
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return const Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(color: Color(0xFFB8FF22)),
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dummy button removed (Antislop C-2). Only real controls.
            IconButton(
              iconSize: 64,
              color: const Color(0xFFB8FF22), // Luma Green Accent
              icon: Icon(
                playing == true ? Icons.pause_circle_filled : Icons.play_circle_filled,
              ),
              onPressed: () {
                if (playing == true) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
