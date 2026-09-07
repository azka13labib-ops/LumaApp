import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

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
  final String _host = 'spotify81.p.rapidapi.com';
  
  String get _apiKey {
    return dotenv.env['RAPIDAPI_KEY'] ?? '';
  }

  /// Search for a song on Spotify81 API (RapidAPI)
  Future<List<MusicItem>> searchMusic(String query) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final encodedQuery = Uri.encodeComponent(query);
      debugPrint('[LumaApp] Memulai pencarian di Spotify81 untuk: $query');
      final request = await client.getUrl(
        Uri.parse('https://$_host/search?q=$encodedQuery&type=tracks&limit=15'),
      ).timeout(const Duration(seconds: 10));
      
      request.headers.set('x-rapidapi-host', _host);
      request.headers.set('x-rapidapi-key', _apiKey);
      
      final response = await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      client.close();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        final List tracks = json['tracks'] ?? [];
        
        return tracks.map((item) {
          final data = item['data'];
          final String id = data['id'];
          final String title = data['name'];
          
          String author = 'Unknown Artist';
          if (data['artists'] != null && data['artists']['items'] != null && data['artists']['items'].isNotEmpty) {
            author = data['artists']['items'][0]['profile']['name'] ?? 'Unknown Artist';
          }
          
          String thumbnailUrl = '';
          if (data['albumOfTrack'] != null && 
              data['albumOfTrack']['coverArt'] != null && 
              data['albumOfTrack']['coverArt']['sources'] != null && 
              data['albumOfTrack']['coverArt']['sources'].isNotEmpty) {
            thumbnailUrl = data['albumOfTrack']['coverArt']['sources'][0]['url'];
          }

          return MusicItem(
            id: id,
            title: title,
            author: author,
            thumbnailUrl: thumbnailUrl,
          );
        }).toList();
      } else {
        debugPrint('[LumaApp] Spotify81 Search Error: ${response.statusCode} - $responseBody');
        if (kIsWeb) return _getWebDummyData(query);
        throw Exception('Gagal mencari lagu (API Error)');
      }
    } catch (e) {
      debugPrint('[LumaApp] Search exception: $e');
      if (kIsWeb) return _getWebDummyData(query);
      rethrow;
    }
  }

  /// Mengambil Audio stream via Spotify81 download_track endpoint
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
      debugPrint('[LumaApp] Fetching audio stream via Spotify81 for: ${item.title}');
      
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final q = Uri.encodeComponent("${item.title} ${item.author}");
      final request = await client.getUrl(
        Uri.parse('https://$_host/download_track?q=$q'),
      ).timeout(const Duration(seconds: 15));
      
      request.headers.set('x-rapidapi-host', _host);
      request.headers.set('x-rapidapi-key', _apiKey);
      
      final response = await request.close().timeout(const Duration(seconds: 15));
      final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 15));
      client.close();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        if (json['youtube'] != null && json['youtube']['download'] != null) {
          final streamUrl = json['youtube']['download']['url'];
          
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
          throw Exception('Format response tidak valid dari Spotify81: $responseBody');
        }
      } else {
        throw Exception('Spotify81 Download Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[LumaApp] Stream extraction error: $e');
      throw Exception('Gagal mendapatkan stream audio: $e');
    }
  }

  void dispose() {
    // nothing to close for httpclient since we close it per request
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
