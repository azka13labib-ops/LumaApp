import 'dart:io';
import 'package:flutter/foundation.dart';
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
  final YoutubeExplode _yt = YoutubeExplode();

  /// Search for a song on YouTube Music
  Future<List<MusicItem>> searchMusic(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      final List<Video> videos = searchResults.toList();

      if (videos.isEmpty && kIsWeb) {
        return _getWebDummyData(query);
      }

      return videos.map((v) => MusicItem(
        id: v.id.value,
        title: v.title,
        author: v.author,
        thumbnailUrl: v.thumbnails.mediumResUrl,
      )).toList();
    } catch (e) {
      if (kIsWeb) return _getWebDummyData(query);
      rethrow;
    }
  }

  /// Get an AudioSource that pipes audio directly via the youtube_explode_dart
  /// HTTP client, avoiding 403 errors caused by URL signing mismatch.
  Future<AudioSource?> getAudioSource(String videoId) async {
    if (videoId == 'dummy_web_id') {
      return AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      );
    }

    try {
      debugPrint('[LumaApp] Fetching manifest for $videoId...');
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      // Pilih MP4/M4A yang paling kompatibel
      final mp4Streams = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.container.name == 'm4a');
      final streamInfo = mp4Streams.isNotEmpty 
          ? mp4Streams.withHighestBitrate() 
          : manifest.audioOnly.withHighestBitrate();
          
      debugPrint('[LumaApp] Stream URL ready: ${streamInfo.url}');

      // Kembali menggunakan Proxy (StreamAudioSource) karena ExoPlayer (AudioSource.uri)
      // ternyata masih diblokir (403) meskipun User-Agent sudah diubah.
      // Dengan proxy ini, kita menggunakan HTTP Client milik youtube_explode_dart.
      return _YoutubeStreamAudioSource(
        streamInfo.url.toString(), 
        streamInfo.size.totalBytes, 
        streamInfo.container.name,
      );
    } catch (e) {
      debugPrint('[LumaApp] Audio source error: $e');
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
        thumbnailUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=300&auto=format&fit=crop',
      ),
    ];
  }
}

/// Custom StreamAudioSource yang meneruskan data audio dari URL
/// dengan mendukung Range Requests (wajib untuk format MP4/WebM).
// ignore: deprecated_member_use
class _YoutubeStreamAudioSource extends StreamAudioSource {
  final String _url;
  final int _totalBytes;
  final String _container;
  // Menggunakan http client biasa tapi menyamar sebagai browser kuat
  final HttpClient _httpClient = HttpClient();

  _YoutubeStreamAudioSource(this._url, this._totalBytes, this._container);

  @override
  // ignore: deprecated_member_use
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _totalBytes;

    debugPrint('[LumaApp] Audio proxy requesting Range: bytes=$start-${end - 1}');

    final request = await _httpClient.getUrl(Uri.parse(_url));
    request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    request.headers.set('Range', 'bytes=$start-${end - 1}');
    
    final response = await request.close();
    
    final stream = response.map((chunk) => chunk);

    // ignore: deprecated_member_use
    return StreamAudioResponse(
      sourceLength: _totalBytes,
      contentLength: response.contentLength > 0 ? response.contentLength : (end - start),
      offset: start,
      stream: stream,
      contentType: 'audio/$_container',
    );
  }
}
