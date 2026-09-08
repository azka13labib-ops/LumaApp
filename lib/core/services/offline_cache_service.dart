import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'youtube_service.dart';

/// Best-effort local MP3 cache. YouTube / CDN URLs may expire for re-download;
/// already-saved files keep working until deleted.
class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));

  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/offline_tracks');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  Future<File> _audioFile(String youtubeId) async {
    final dir = await _cacheDir();
    return File('${dir.path}/$youtubeId.mp3');
  }

  Future<File> _metaFile(String youtubeId) async {
    final dir = await _cacheDir();
    return File('${dir.path}/$youtubeId.json');
  }

  Future<bool> isCached(String youtubeId) async {
    try {
      return await (await _audioFile(youtubeId)).exists();
    } catch (_) {
      return false;
    }
  }

  Future<String?> localPath(String youtubeId) async {
    final file = await _audioFile(youtubeId);
    if (await file.exists()) return file.path;
    return null;
  }

  Future<void> download(MusicItem item, String streamUrl) async {
    final file = await _audioFile(item.id);
    final meta = await _metaFile(item.id);
    debugPrint('[Offline] Downloading ${item.title} → ${file.path}');
    await _dio.download(streamUrl, file.path);
    await meta.writeAsString(jsonEncode({
      'id': item.id,
      'title': item.title,
      'author': item.author,
      'thumbnailUrl': item.thumbnailUrl,
      'savedAt': DateTime.now().toIso8601String(),
    }));
  }

  Future<void> remove(String youtubeId) async {
    final audio = await _audioFile(youtubeId);
    final meta = await _metaFile(youtubeId);
    if (await audio.exists()) await audio.delete();
    if (await meta.exists()) await meta.delete();
  }

  Future<List<MusicItem>> listCached() async {
    final dir = await _cacheDir();
    final items = <MusicItem>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final map = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        final id = map['id'] as String? ?? '';
        if (id.isEmpty) continue;
        if (!await isCached(id)) continue;
        items.add(MusicItem(
          id: id,
          title: map['title'] as String? ?? 'Tanpa judul',
          author: map['author'] as String? ?? 'Tidak diketahui',
          thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
        ));
      } catch (e) {
        debugPrint('[Offline] meta read error: $e');
      }
    }
    items.sort((a, b) => a.title.compareTo(b.title));
    return items;
  }
}
