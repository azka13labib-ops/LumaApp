import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'offline_cache_service.dart';

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

  factory MusicItem.fromMap(
    Map<String, dynamic> row, {
    String missingTitle = '',
    String missingArtist = '',
  }) {
    return MusicItem(
      id: row['youtube_id'] ?? '',
      title: row['title'] ?? missingTitle,
      author: row['artist'] ?? row['author'] ?? missingArtist,
      thumbnailUrl: row['cover_url'] ?? row['thumbnail'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MusicItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class YouTubeService {
  final String _host = 'youtube-mp36.p.rapidapi.com';
  final YoutubeExplode _yt = YoutubeExplode();

  String get _apiKey {
    return dotenv.env['RAPIDAPI_KEY'] ?? '';
  }

  MediaItem _mediaTag(MusicItem item) => MediaItem(
        id: item.id,
        title: item.title,
        artist: item.author,
        artUri: item.thumbnailUrl.isNotEmpty ? Uri.tryParse(item.thumbnailUrl) : null,
      );

  /// Search music — filters out non-music results:
  /// - max 15 min duration (avoids podcasts, full albums)
  /// - min 1 min (avoids 30s clips)
  Future<List<MusicItem>> searchMusic(String query) async {
    try {
      debugPrint('[LumaApp] Searching YouTube: $query');
      final searchResults = await _yt.search.search(query);
      return searchResults
          .where((v) =>
              v.duration != null &&
              v.duration!.inMinutes >= 1 &&
              v.duration!.inMinutes < 15)
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

  /// Resolve remote MP3 URL (for streaming or offline download).
  Future<String?> resolveStreamUrl(MusicItem item) async {
    if (item.id == 'dummy_web_id') {
      return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);

    try {
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
            return json['link'] as String;
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
      throw Exception('Timeout: audio conversion took too long');
    } finally {
      client.close(force: true);
    }
  }

  /// Cache-First: prefer local file → fall back to CDN stream.
  Future<AudioSource?> getAudioSource(MusicItem item) async {
    final local = await OfflineCacheService.instance.localPath(item.id);
    if (local != null) {
      debugPrint('[LumaApp] Playing offline: $local');
      return AudioSource.file(local, tag: _mediaTag(item));
    }

    try {
      debugPrint('[LumaApp] Getting audio via youtube-mp36 for: ${item.title}');
      final link = await resolveStreamUrl(item);
      if (link == null) return null;
      debugPrint('[LumaApp] Got MP3 link: $link');
      return AudioSource.uri(Uri.parse(link), tag: _mediaTag(item));
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
