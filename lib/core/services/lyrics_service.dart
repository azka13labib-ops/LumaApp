import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Static lyrics only — on-demand fetch, light in-memory cache.
/// Uses LRCLIB (free, no API key). No synced/karaoke timing.
class LyricsService {
  LyricsService._();
  static final LyricsService instance = LyricsService._();

  final Map<String, String?> _cache = {};

  String _key(String title, String artist) =>
      '${artist.trim().toLowerCase()}|${title.trim().toLowerCase()}';

  /// Returns plain lyric text, empty-string meaning "not found", null only on hard failure.
  Future<String?> fetch({required String title, required String artist}) async {
    final cacheKey = _key(title, artist);
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    // Strip common YouTube noise: "(Official Video)", "[Lyrics]", etc.
    final cleanTitle = title
        .replaceAll(RegExp(r'\([^)]*\)|\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cleanArtist = artist
        .replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '')
        .replaceAll(RegExp(r'VEVO$', caseSensitive: false), '')
        .trim();

    try {
      final q = Uri.encodeQueryComponent('$cleanArtist $cleanTitle');
      final uri = Uri.parse('https://lrclib.net/api/search?q=$q');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 12));
      req.headers.set('User-Agent', 'LumaApp/1.0 (https://github.com/ngodink/LumaApp)');
      final res = await req.close().timeout(const Duration(seconds: 12));
      final body = await res.transform(utf8.decoder).join();
      client.close(force: true);

      if (res.statusCode != 200) {
        debugPrint('[Lyrics] HTTP ${res.statusCode}');
        _cache[cacheKey] = '';
        return '';
      }

      final list = jsonDecode(body) as List<dynamic>? ?? [];
      String? plain;
      for (final raw in list) {
        if (raw is! Map) continue;
        final text = (raw['plainLyrics'] as String?)?.trim();
        if (text != null && text.isNotEmpty) {
          plain = text;
          break;
        }
      }

      _cache[cacheKey] = plain ?? '';
      return _cache[cacheKey];
    } catch (e) {
      debugPrint('[Lyrics] fetch error: $e');
      // Don't cache hard failures — allow retry
      return null;
    }
  }
}
