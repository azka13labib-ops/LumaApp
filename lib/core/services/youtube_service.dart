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
  final String _host = 'youtube-mp36.p.rapidapi.com';
  final YoutubeExplode _yt = YoutubeExplode();
  
  String get _apiKey {
    return dotenv.env['RAPIDAPI_KEY'] ?? '';
  }

  /// Pencarian menggunakan YoutubeExplode (Gratis, Cepat, Tanpa Limit API)
  Future<List<MusicItem>> searchMusic(String query) async {
    try {
      debugPrint('[LumaApp] Memulai pencarian di YouTube untuk: $query');
      
      final searchResults = await _yt.search.search(query);
      
      // Filter hanya video musik (biasanya durasinya wajar dan ada author)
      return searchResults
          .where((v) => v.duration != null && v.duration!.inMinutes < 15) // Abaikan video terlalu panjang
          .map((video) {
            return MusicItem(
              id: video.id.value,
              title: video.title,
              author: video.author,
              thumbnailUrl: video.thumbnails.highResUrl,
            );
          }).toList();
    } catch (e) {
      debugPrint('[LumaApp] Search exception: $e');
      if (kIsWeb) return _getWebDummyData(query);
      rethrow;
    }
  }

  /// Mengambil Audio stream via youtube-mp36 (Seperti screenshot User)
  Future<AudioSource?> getAudioSource(MusicItem item) async {
    if (item.id == 'dummy_web_id') {
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
      debugPrint('[LumaApp] Fetching audio stream via youtube-mp36 untuk ID: ${item.id}');
      
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      
      // Polling loop jika progress belum 100% (bisa memakan waktu beberapa detik di server)
      for (int i = 0; i < 5; i++) {
        final request = await client.getUrl(
          Uri.parse('https://$_host/dl?id=${item.id}'),
        ).timeout(const Duration(seconds: 20));
        
        request.headers.set('x-rapidapi-host', _host);
        request.headers.set('x-rapidapi-key', _apiKey);
        
        final response = await request.close().timeout(const Duration(seconds: 20));
        final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final json = jsonDecode(responseBody);
          
          // API merespons dengan link langsung jika sudah selesai diconvert
          if (json['status'] == 'ok' && json['link'] != null && json['msg'] == 'success') {
            final streamUrl = json['link'];
            client.close();
            
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
          } else if (json['msg'] == 'in progress' || (json['progress'] != null && json['progress'] < 100)) {
            // Jika sedang diproses, tunggu 3 detik lalu coba lagi
            debugPrint('[LumaApp] youtube-mp36 sedang memproses (Progress: ${json['progress']}%). Menunggu 3 detik...');
            await Future.delayed(const Duration(seconds: 3));
            continue;
          } else {
             // Error dari API
             throw Exception('Format response tidak valid dari youtube-mp36: $responseBody');
          }
        } else if (response.statusCode == 429) {
          // Rate limited (Batas per menit API)
          debugPrint('[LumaApp] Rate limited by youtube-mp36. Menunggu 3 detik...');
          await Future.delayed(const Duration(seconds: 3));
          continue;
        } else {
          throw Exception('youtube-mp36 Error: ${response.statusCode}');
        }
      }
      
      client.close();
      throw Exception('Timeout saat memproses audio di youtube-mp36. Coba lagu lain.');
      
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
