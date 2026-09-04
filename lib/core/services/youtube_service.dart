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
        Uri.parse(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        ),
      );
    }

    try {
      debugPrint('[LumaApp] Fetching manifest for video: $videoId');
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      // Start a local proxy server in Dart to fetch the stream
      // This bypasses ExoPlayer's 403 blocks because Dart's HttpClient fetches it
      final proxyUrl = await _startLocalProxy(
        videoId,
        audioStreamInfo.url.toString(),
      );
      debugPrint('[LumaApp] Local proxy URL ready: $proxyUrl');

      return AudioSource.uri(Uri.parse(proxyUrl));
    } catch (e) {
      debugPrint('[LumaApp] Audio source error: $e');
      return null;
    }
  }

  HttpServer? _localServer;

  Future<String> _startLocalProxy(
    String videoId,
    String initialTargetUrl,
  ) async {
    // Tutup server lama jika ada
    if (_localServer != null) {
      await _localServer!.close();
    }

    _localServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = _localServer!.port;

    _localServer!.listen((HttpRequest request) async {
      final client = HttpClient()..autoUncompress = false;
      try {
        var targetUrl = initialTargetUrl;
        var targetResponse = await _openStreamRequest(
          client,
          request,
          targetUrl,
        );

        // Stream URLs from YouTube can expire or be rejected after the
        // manifest was created. Refresh the manifest once before giving up.
        if (targetResponse.statusCode == HttpStatus.forbidden) {
          await targetResponse.drain();
          final refreshedManifest = await _yt.videos.streamsClient.getManifest(
            videoId,
          );
          targetUrl =
              refreshedManifest.audioOnly.withHighestBitrate().url.toString();
          targetResponse = await _openStreamRequest(client, request, targetUrl);
        }

        request.response.statusCode = targetResponse.statusCode;
        final headersToForward = <String>{
          HttpHeaders.acceptRangesHeader,
          HttpHeaders.contentLengthHeader,
          HttpHeaders.contentRangeHeader,
          HttpHeaders.contentTypeHeader,
          HttpHeaders.etagHeader,
          HttpHeaders.lastModifiedHeader,
        };
        targetResponse.headers.forEach((name, values) {
          if (headersToForward.contains(name.toLowerCase())) {
            for (final value in values) {
              request.response.headers.add(name, value);
            }
          }
        });

        if (request.method == 'HEAD') {
          await targetResponse.drain();
          await request.response.close();
        } else {
          await targetResponse.pipe(request.response);
        }
      } catch (e, stackTrace) {
        debugPrint('[LumaApp] Proxy error: $e');
        debugPrint('$stackTrace');
        try {
          request.response.statusCode = HttpStatus.badGateway;
        } catch (_) {}
        await request.response.close();
      } finally {
        client.close(force: true);
      }
    });

    return 'http://127.0.0.1:$port/';
  }

  Future<HttpClientResponse> _openStreamRequest(
    HttpClient client,
    HttpRequest request,
    String targetUrl,
  ) async {
    final targetRequest = await client.getUrl(Uri.parse(targetUrl));
    targetRequest.headers
      ..set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
      )
      ..set(HttpHeaders.acceptHeader, '*/*')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9')
      ..set('referer', 'https://www.youtube.com/');

    final range = request.headers.value(HttpHeaders.rangeHeader);
    if (range != null) {
      targetRequest.headers.set(HttpHeaders.rangeHeader, range);
    }

    return targetRequest.close();
  }

  void dispose() {
    _localServer?.close(force: true);
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
