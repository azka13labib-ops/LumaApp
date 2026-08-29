import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String artist;
  final String coverUrl;

  const PlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.artist,
    required this.coverUrl,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    // TODO: Fetch audio URL from youtube_service and play it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(widget.coverUrl, width: 200, height: 200),
            const SizedBox(height: 20),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            Text(widget.artist, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous), onPressed: () {}),
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 48),
                  onPressed: () {},
                ),
                IconButton(icon: const Icon(Icons.skip_next), onPressed: () {}),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
