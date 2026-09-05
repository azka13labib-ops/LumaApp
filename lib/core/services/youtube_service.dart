import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Search for a song on YouTube
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

  /// Downloads the full audio to a temp file using youtube_explode_dart's own
  /// authenticated HTTP client, then plays from local file:// URI.
  /// Falls back to Deezer 30-sec preview if YouTube rate-limits this IP.
  Future<AudioSource?> getAudioSource(MusicItem item) async {
    final videoId = item.id;

    if (videoId == 'dummy_web_id') {
      return AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      );
    }

    try {
      debugPrint('[LumaApp] Fetching manifest for: $videoId');
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Prefer mp4/m4a for widest Android codec support
      final audioInfo = manifest.audioOnly.firstWhere(
        (s) => s.codec.mimeType.contains('mp4'),
        orElse: () => manifest.audioOnly.withHighestBitrate(),
      );

      final ext = audioInfo.codec.mimeType.contains('mp4') ? 'm4a' : 'webm';
      debugPrint(
        '[LumaApp] Downloading ${audioInfo.size.totalBytes} bytes '
        '(${audioInfo.codec.mimeType}) to temp file...',
      );

      // Reuse cached file if it's still fresh (< 30 min old)
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$videoId.$ext');
      if (await file.exists()) {
        final age = DateTime.now().difference((await file.stat()).modified);
        if (age.inMinutes < 30) {
          debugPrint('[LumaApp] Using cached file: ${file.path}');
          return AudioSource.uri(Uri.file(file.path));
        }
        await file.delete();
      }

      // Stream audio bytes via youtube_explode_dart's own HTTP client
      // (carries signed YouTube cookies — no 403)
      final sink = file.openWrite();
      await _yt.videos.streamsClient.get(audioInfo).pipe(sink);
      await sink.flush();
      await sink.close();

      debugPrint('[LumaApp] Download complete: ${file.path}');
      return AudioSource.uri(Uri.file(file.path));
    } on RequestLimitExceededException {
      // YouTube is rate-limiting this IP — fall back to Deezer 30-sec preview
      debugPrint('[LumaApp] YouTube rate-limited. Falling back to Deezer preview...');
      return _getDeezerFallback(item);
    } catch (e, stack) {
      debugPrint('[LumaApp] Audio source error: $e');
      debugPrint('[LumaApp] $stack');
      return null;
    }
  }

  /// Searches Deezer for a matching track and returns its 30-second preview.
  Future<AudioSource?> _getDeezerFallback(MusicItem item) async {
    try {
      final q = Uri.encodeQueryComponent('${item.title} ${item.author}');
      final client = HttpClient()..userAgent = 'Mozilla/5.0';
      final req = await client.getUrl(
        Uri.parse('https://api.deezer.com/search?q=$q&limit=1'),
      );
      final res = await req.close();
      final body = await res.transform(const Utf8Decoder()).join();
      client.close();
      if (res.statusCode != 200) return null;
      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;
      final preview = data.first['preview'] as String?;
      if (preview == null || preview.isEmpty) return null;
      debugPrint('[LumaApp] Deezer fallback preview: $preview');
      return AudioSource.uri(
        Uri.parse(preview),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 11) Chrome/120',
          'Referer': 'https://www.deezer.com/',
        },
      );
    } catch (e) {
      debugPrint('[LumaApp] Deezer fallback error: $e');
      return null;
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
