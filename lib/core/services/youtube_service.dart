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
  final String? localThumbnailPath;
  final int? fileSizeBytes;

  MusicItem({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    this.localThumbnailPath,
    this.fileSizeBytes,
  });

  MusicItem copyWith({
    String? id,
    String? title,
    String? author,
    String? thumbnailUrl,
    String? localThumbnailPath,
    int? fileSizeBytes,
  }) {
    return MusicItem(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  factory MusicItem.fromMap(
    Map<String, dynamic> row, {
    String missingTitle = '',
    String missingArtist = '',
  }) {
    return MusicItem(
      id: row['youtube_id'] ?? row['id'] ?? '',
      title: row['title'] ?? missingTitle,
      author: row['artist'] ?? row['author'] ?? missingArtist,
      thumbnailUrl: row['cover_url'] ?? row['thumbnail'] ?? '',
      localThumbnailPath: row['local_thumbnail_path'],
      fileSizeBytes: row['file_size_bytes'],
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

  /// Resolve remote audio stream URL (for streaming or offline download).
  /// 1. Primary: youtube_explode_dart native manifest stream (Fast, Hi-Res, zero rate-limit)
  /// 2. Fallback: RapidAPI youtube-mp36 (if native manifest fails)
  Future<String?> resolveStreamUrl(MusicItem item) async {
    if (item.id == 'dummy_web_id') {
      return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    }

    // 1. Primary: Direct YouTube native audio stream
    try {
      debugPrint('[LumaApp] Resolving native stream for: ${item.id}');
      final manifest = await _yt.videos.streamsClient.getManifest(item.id);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      debugPrint('[LumaApp] Native stream resolved: ${audioStream.bitrate} ${audioStream.container.name}');
      return audioStream.url.toString();
    } catch (e) {
      debugPrint('[LumaApp] Native stream resolution failed ($e), falling back to RapidAPI...');
    }

    // 2. Fallback to RapidAPI only if native failed and API key exists
    if (_apiKey.isEmpty) return null;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      for (int attempt = 0; attempt < 2; attempt++) {
        final request = await client
            .getUrl(Uri.parse('https://$_host/dl?id=${item.id}'))
            .timeout(const Duration(seconds: 10));

        request.headers.set('x-rapidapi-host', _host);
        request.headers.set('x-rapidapi-key', _apiKey);

        final response =
            await request.close().timeout(const Duration(seconds: 10));
        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(body);
          if (json['status'] == 'ok' &&
              json['msg'] == 'success' &&
              json['link'] != null) {
            return json['link'] as String;
          } else if (json['msg'] == 'in progress' ||
              (json['progress'] != null && json['progress'] < 100)) {
            await Future.delayed(const Duration(seconds: 2));
          } else {
            break;
          }
        } else {
          break;
        }
      }
    } catch (e) {
      debugPrint('[LumaApp] RapidAPI fallback error: $e');
    } finally {
      client.close(force: true);
    }
    return null;
  }

  /// Cache-First: prefer local file → fall back to CDN stream.
  Future<AudioSource?> getAudioSource(MusicItem item) async {
    final local = await OfflineCacheService.instance.localPath(item.id);
    if (local != null) {
      debugPrint('[LumaApp] Playing offline: $local');
      return AudioSource.file(local, tag: _mediaTag(item));
    }

    try {
      debugPrint('[LumaApp] Getting audio stream for: ${item.title}');
      final link = await resolveStreamUrl(item);
      if (link == null) return null;
      debugPrint('[LumaApp] Got audio link: $link');
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
