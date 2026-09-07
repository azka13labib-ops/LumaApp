import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MusicItem {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;

  MusicItem({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
  });
}

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Search for a song on YouTube (Paling Akurat)
  Future<List<MusicItem>> searchMusic(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      final List<Video> videos = searchResults.toList();

      if (videos.isEmpty && kIsWeb) {
        return _getWebDummyData(query);
      }

      return videos
          .map(
            (v) => MusicItem(
              id: v.id.value,
              title: v.title,
              author: v.author,
              thumbnailUrl: v.thumbnails.mediumResUrl,
            ),
          )
          .toList();
    } catch (e, stack) {
      debugPrint('[LumaApp] Search error: $e');
      debugPrint('[LumaApp] Search stackTrace: $stack');
      if (kIsWeb) return _getWebDummyData(query);
      rethrow;
    }
  }

  /// Mengambil Audio menggunakan YoutubeExplode
  Future<AudioSource?> getAudioSource(MusicItem item) async {
    final videoId = item.id;

    if (videoId == 'dummy_web_id') {
      return AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
        tag: MediaItem(
          id: item.id,
          album: 'LumaApp',
          title: item.title,
          artist: item.author,
          artUri: Uri.parse(item.thumbnailUrl),
        ),
      );
    }

    try {
      debugPrint('[LumaApp] Fetching audio stream via YoutubeExplode for: $videoId');
      
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      
      return AudioSource.uri(
        streamInfo.url,
        tag: MediaItem(
          id: item.id,
          album: 'LumaApp',
          title: item.title,
          artist: item.author,
          artUri: Uri.parse(item.thumbnailUrl),
        ),
      );
    } catch (e) {
      debugPrint('[LumaApp] Stream extraction error: $e');
      throw Exception('Gagal mendapatkan stream audio: $e');
    }
  }

  void dispose() {
    _yt.close();
  }

  List<MusicItem> _getWebDummyData(String query) {
    return [
      MusicItem(
        id: 'dummy_web_id',
        title: '$query (Web Preview Mode)',
        author: 'Luma Studio',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=300&auto=format&fit=crop',
      ),
    ];
  }
}
