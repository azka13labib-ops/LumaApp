import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  /// Mengambil Audio. 
  /// Sepenuhnya menggunakan RapidAPI (youtube-mp36)
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
      debugPrint('[LumaApp] Mencoba RapidAPI (youtube-mp36) untuk: $videoId');
      
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(
        Uri.parse('https://youtube-mp36.p.rapidapi.com/dl?id=$videoId'),
      );
      
      // Baca API Key dari .env (jangan hardcode — R-38)
      final apiKey = dotenv.env['RAPIDAPI_KEY'] ?? '';
      request.headers.set('x-rapidapi-host', 'youtube-mp36.p.rapidapi.com');
      request.headers.set('x-rapidapi-key', apiKey);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        
        if (json['status'] == 'ok' && json['link'] != null) {
          final streamUrl = json['link'];
          debugPrint('[LumaApp] RapidAPI Sukses! Link MP3: $streamUrl');
          return AudioSource.uri(
            Uri.parse(streamUrl),
            tag: MediaItem(
              id: item.id,
              album: 'LumaApp',
              title: item.title,
              artist: item.author,
              artUri: Uri.parse(item.thumbnailUrl),
            ),
          );
        } else {
          debugPrint('[LumaApp] RapidAPI merespon tapi error: $responseBody');
          throw Exception('Gagal mendapatkan link MP3 dari API.');
        }
      } else {
        debugPrint('[LumaApp] RapidAPI gagal: ${response.statusCode} - $responseBody');
        throw Exception('RapidAPI Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[LumaApp] RapidAPI Exception: $e');
      throw Exception('Gagal memutar audio melalui RapidAPI. Periksa kuota Anda.');
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
