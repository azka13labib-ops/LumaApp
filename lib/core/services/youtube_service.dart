import 'dart:convert';
import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'offline_cache_service.dart';
import 'settings_service.dart';

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

  /// Search music:
  /// 1. Tries youtube_explode_dart
  /// 2. If it throws (e.g. NoSuchMethodError on getT or parsing error) or returns 0 matches,
  ///    falls back to YouTube InnerTube search which is robust and never crashes.
  Future<List<MusicItem>> searchMusic(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];
    final safeQuery = cleanQuery.length > 200 ? cleanQuery.substring(0, 200) : cleanQuery;

    try {
      debugPrint('[LumaApp] Searching YouTube: $safeQuery');
      final searchResults = await _yt.search.search(safeQuery);
      
      // Filter out extreme lengths (full albums > 30 min or tiny audio clips < 45s)
      var filtered = searchResults
          .where((v) =>
              v.duration != null &&
              v.duration!.inSeconds >= 45 &&
              v.duration!.inMinutes < 25)
          .map((video) => MusicItem(
                id: video.id.value,
                title: video.title,
                author: video.author,
                thumbnailUrl: video.thumbnails.highResUrl,
              ))
          .toList();

      // If strict filter yielded no results, relax filter to return whatever matches
      if (filtered.isEmpty && searchResults.isNotEmpty) {
        filtered = searchResults
            .map((video) => MusicItem(
                  id: video.id.value,
                  title: video.title,
                  author: video.author,
                  thumbnailUrl: video.thumbnails.highResUrl,
                ))
            .toList();
      }

      if (filtered.isNotEmpty) return filtered;
    } catch (e) {
      debugPrint('[LumaApp] YouTubeExplode search failed ($e), falling back to InnerTube search...');
    }

    // Fallback to InnerTube search endpoint
    final innerTubeResults = await _searchInnerTube(safeQuery);
    if (innerTubeResults.isNotEmpty) {
      return innerTubeResults;
    }

    if (kIsWeb) return _getWebDummyData(safeQuery);
    return const [];
  }

  /// InnerTube direct search fallback (Official YouTube Web Client API)
  Future<List<MusicItem>> _searchInnerTube(String query) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final targetUrl = 'https://www.youtube.com/youtubei/v1/search';
      final url = kIsWeb 
          ? 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}'
          : targetUrl;
      final uri = Uri.parse(url);
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 10));
      request.headers.set('content-type', 'application/json');
      request.headers.set('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

      final payload = {
        'context': {
          'client': {
            'clientName': 'WEB',
            'clientVersion': '2.20240101.01.00',
            'hl': 'id',
            'gl': 'ID',
          }
        },
        'query': query,
      };
      request.write(jsonEncode(payload));
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final sectionList = json['contents']?['twoColumnSearchResultsRenderer']
          ?['primaryContents']?['sectionListRenderer']?['contents'] as List?;
      if (sectionList == null) return const [];

      final items = <MusicItem>[];
      for (final sec in sectionList) {
        final itemSection = sec['itemSectionRenderer']?['contents'] as List?;
        if (itemSection == null) continue;
        for (final item in itemSection) {
          final vr = item['videoRenderer'];
          if (vr == null) continue;
          final videoId = vr['videoId'] as String?;
          if (videoId == null || videoId.isEmpty) continue;

          final title = vr['title']?['runs']?[0]?['text'] ??
              vr['title']?['simpleText'] ??
              '';
          final author = vr['ownerText']?['runs']?[0]?['text'] ??
              vr['shortBylineText']?['runs']?[0]?['text'] ??
              '';
          final thumbList = vr['thumbnail']?['thumbnails'] as List?;
          final thumb = (thumbList != null && thumbList.isNotEmpty)
              ? thumbList.last['url'] as String?
              : null;

          items.add(MusicItem(
            id: videoId,
            title: title.toString(),
            author: author.toString(),
            thumbnailUrl: thumb ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
          ));
        }
      }
      return items;
    } catch (e) {
      debugPrint('[LumaApp] InnerTube search error: $e');
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  /// Resolve remote audio stream URL (for streaming or offline download).
  /// 1. Primary: youtube_explode_dart native manifest stream (Fast, Hi-Res, zero rate-limit)
  /// 2. Fallback: RapidAPI youtube-mp36 (if native manifest fails or if forceRapidApi is true)
  Future<String?> resolveStreamUrl(
    MusicItem item, {
    AudioQuality quality = AudioQuality.auto,
    bool forceRapidApi = false,
  }) async {
    final cleanId = item.id.trim();
    if (cleanId.isEmpty) return null;

    if (cleanId == 'dummy_web_id') {
      return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    }

    // 1. Primary: Direct YouTube native audio stream (unless forceRapidApi is requested)
    if (!forceRapidApi) {
      try {
        debugPrint('[LumaApp] Resolving native stream for: $cleanId with quality: ${quality.name}');
        final manifest = await _yt.videos.streamsClient.getManifest(cleanId);
        final streams = manifest.audioOnly.toList();

        AudioStreamInfo audioStream;
        if (streams.isEmpty) {
          audioStream = manifest.audioOnly.withHighestBitrate();
        } else {
          // Prioritize MP4/AAC for universal Android device playback
          final mp4Streams = streams
              .where((s) => s.container.name.toLowerCase() == 'mp4')
              .toList();
          final pool = mp4Streams.isNotEmpty ? mp4Streams : streams;
          pool.sort((a, b) => a.bitrate.compareTo(b.bitrate));

          audioStream = switch (quality) {
            AudioQuality.dataSaver => pool.first,
            AudioQuality.standard =>
              pool.length > 1 ? pool[pool.length ~/ 2] : pool.first,
            AudioQuality.high || AudioQuality.auto => pool.last,
          };
        }

        debugPrint('[LumaApp] Native stream resolved: ${audioStream.bitrate} ${audioStream.container.name}');
        return audioStream.url.toString();
      } catch (e) {
        debugPrint('[LumaApp] Native stream resolution failed ($e), falling back to RapidAPI...');
      }
    }

    // 2. Fallback to RapidAPI only if native failed / forced and API key exists
    if (_apiKey.isEmpty) return null;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      for (int attempt = 0; attempt < 2; attempt++) {
        final targetUrl = 'https://$_host/dl?id=$cleanId';
        final url = kIsWeb 
            ? 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}'
            : targetUrl;
        final uri = Uri.parse(url);
        final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));

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
  Future<AudioSource?> getAudioSource(
    MusicItem item, {
    AudioQuality quality = AudioQuality.auto,
    bool forceRapidApi = false,
  }) async {
    final local = await OfflineCacheService.instance.localPath(item.id);
    if (local != null) {
      debugPrint('[LumaApp] Playing offline: $local');
      return AudioSource.file(local, tag: _mediaTag(item));
    }

    try {
      debugPrint('[LumaApp] Getting audio stream for: ${item.title} (forceRapidApi: $forceRapidApi)');
      final link = await resolveStreamUrl(item, quality: quality, forceRapidApi: forceRapidApi);
      if (link == null) return null;
      return AudioSource.uri(
        Uri.parse(link),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Range': 'bytes=0-',
        },
        tag: _mediaTag(item),
      );
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
