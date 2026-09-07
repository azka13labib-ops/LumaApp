import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
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
  final String _host = 'youtube-mp36.p.rapidapi.com';
  final YoutubeExplode _yt = YoutubeExplode();

  String get _apiKey {
    return dotenv.env['RAPIDAPI_KEY'] ?? '';
  }

  /// Pencarian menggunakan YoutubeExplode (Gratis, Cepat)
  Future<List<MusicItem>> searchMusic(String query) async {
    try {
      debugPrint('[LumaApp] Searching YouTube: $query');
      final searchResults = await _yt.search.search(query);
      return searchResults
          .where((v) => v.duration != null && v.duration!.inMinutes < 15)
          .map((video) => MusicItem(
                id: video.id.value,
                title: video.title,
                author: video.author,
                thumbnailUrl: video.thumbnails.highResUrl,
              ))
          .toList();
    } catch (e) {
      debugPrint('[LumaApp] Search exception: $e');
      if (kIsWeb) return _getWebDummyData(query);
      rethrow;
    }
  }

  /// Mengambil Audio stream via youtube-mp36 API
  Future<AudioSource?> getAudioSource(MusicItem item) async {
    if (item.id == 'dummy_web_id') {
      return AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      );
    }

    try {
      debugPrint('[LumaApp] Getting audio via youtube-mp36 for: ${item.title}');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 20);

      for (int attempt = 0; attempt < 5; attempt++) {
        final request = await client
            .getUrl(Uri.parse('https://$_host/dl?id=${item.id}'))
            .timeout(const Duration(seconds: 20));

        request.headers.set('x-rapidapi-host', _host);
        request.headers.set('x-rapidapi-key', _apiKey);

        final response =
            await request.close().timeout(const Duration(seconds: 20));
        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final json = jsonDecode(body);

          if (json['status'] == 'ok' &&
              json['msg'] == 'success' &&
              json['link'] != null) {
            client.close();
            debugPrint('[LumaApp] Got MP3 link: ${json['link']}');
            return AudioSource.uri(Uri.parse(json['link'] as String));
          } else if (json['msg'] == 'in progress' ||
              (json['progress'] != null && json['progress'] < 100)) {
            debugPrint(
                '[LumaApp] API in progress (${json['progress']}%), retrying...');
            await Future.delayed(const Duration(seconds: 3));
          } else {
            throw Exception('Unexpected API response: $body');
          }
        } else if (response.statusCode == 429) {
          debugPrint('[LumaApp] Rate limited, waiting 5s...');
          await Future.delayed(const Duration(seconds: 5));
        } else {
          throw Exception('youtube-mp36 HTTP error: ${response.statusCode}');
        }
      }

      client.close();
      throw Exception('Timeout: audio conversion took too long');
    } catch (e) {
      debugPrint('[LumaApp] getAudioSource error: $e');
      throw Exception('Gagal mendapatkan stream: $e');
    }
  }

  void dispose() {
    _yt.close();
  }

  List<MusicItem> _getWebDummyData(String query) {
    return [
      MusicItem(
        id: 'dummy_web_id',
        title: '$query (Preview)',
        author: 'Luma Studio',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=300',
      ),
    ];
  }
}
